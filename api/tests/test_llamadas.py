import unittest
from unittest.mock import MagicMock, patch

from core.auth import crear_token
from core.config import configuracion
from main import crear_app
from services.call_service import register_call


class LlamadasTests(unittest.TestCase):
    def setUp(self):
        self.secret = patch.object(configuracion, 'jwt_secreto', 'test-only-secret-for-llamadas-tests')
        self.secret.start()
        self.addCleanup(self.secret.stop)
        self.app = crear_app()
        self.client = self.app.test_client()
        self.headers = {'Authorization': 'Bearer ' + crear_token({'id': 37, 'rol': 'TELEFONISTA'})}

    def test_routes_require_session_and_telefonista(self):
        for method, path in [('get', '/llamadas/form-options'), ('get', '/llamadas/donantes/8'),
                             ('post', '/donantes/8/llamadas')]:
            with self.subTest(path=path):
                self.assertEqual(getattr(self.client, method)(path).status_code, 401)
                token = crear_token({'id': 9, 'rol': 'RECOLECTOR'})
                response = getattr(self.client, method)(path, headers={'Authorization': 'Bearer ' + token})
                self.assertEqual(response.status_code, 403)

    @patch('routers.llamadas.register_call')
    def test_uses_identity_from_login_not_payload(self, register):
        register.return_value = {'id_llamada': 12, 'id_donativo': 91}
        payload = {'resultado': 'PROMESA', 'id_usuario': 2, 'compromiso': {}}
        response = self.client.post('/donantes/8/llamadas', json=payload, headers=self.headers)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json['id_donativo'], 91)
        register.assert_called_once_with(donor_id=8, data=payload, user_id=37)

    def test_original_donor_route_remains_unique(self):
        routes = [r for r in self.app.url_map.iter_rules() if r.rule == '/donantes/<int:donante_id>']
        self.assertEqual(len(routes), 1)
        self.assertEqual(routes[0].endpoint, 'donantes.obtener_donante')

    @patch('routers.llamadas.obtener_conexion')
    def test_renamed_donor_route(self, connection):
        connection.return_value.cursor.return_value.fetchone.return_value = (8, 'Donante prueba')
        response = self.client.get('/llamadas/donantes/8', headers=self.headers)
        self.assertEqual(response.json, {'id': 8, 'nombre': 'Donante prueba'})
        connection.return_value.cursor.return_value.fetchone.return_value = None
        self.assertEqual(self.client.get('/llamadas/donantes/8', headers=self.headers).status_code, 404)

    def test_invalid_payloads_return_400(self):
        for payload in [[], ['bad'], {'resultado': []}, {'resultado': 'PROMESA', 'compromiso': 'bad'},
                        {'resultado': 'NO_CONTESTO', 'compromiso': {}}, {'resultado': 'RECHAZO', 'comentarios': 3}]:
            with self.subTest(payload=payload):
                response = self.client.post('/donantes/8/llamadas', json=payload, headers=self.headers)
                self.assertEqual(response.status_code, 400)

    @patch('services.call_service.obtener_conexion')
    def test_call_and_commitment_commit_together(self, connection):
        conn = connection.return_value
        cursor = conn.cursor.return_value
        cursor.fetchone.side_effect = [(1,), (12,), (1,), (1,), (91,)]
        result = register_call(8, {'resultado': 'PROMESA', 'compromiso': {
            'importe': 250, 'id_forma_pago': 1, 'pago_unico': True}}, 37)
        self.assertEqual(result, {'id_llamada': 12, 'id_donativo': 91})
        self.assertEqual(cursor.execute.call_args_list[1].args[1], (8, 37, 'PROMESA', None))
        conn.commit.assert_called_once()
        conn.rollback.assert_not_called()
        conn.close.assert_not_called()  # Shared connection belongs to Flask's teardown.

    @patch('services.call_service.obtener_conexion')
    def test_no_answer_does_not_create_commitment(self, connection):
        conn = connection.return_value
        conn.cursor.return_value.fetchone.side_effect = [(1,), (12,)]
        result = register_call(8, {'resultado': 'NO_CONTESTO'}, 37)
        self.assertIsNone(result['id_donativo'])
        self.assertEqual(conn.cursor.return_value.execute.call_count, 2)
        conn.commit.assert_called_once()

    @patch('services.call_service.obtener_conexion')
    def test_invalid_commitment_rolls_back_call(self, connection):
        for amount in [0, -2, 'bad', True, float('inf'), float('nan')]:
            with self.subTest(amount=amount):
                conn = MagicMock()
                connection.return_value = conn
                conn.cursor.return_value.fetchone.side_effect = [(1,), (12,)]
                with self.assertRaises(ValueError):
                    register_call(8, {'resultado': 'PROMESA', 'compromiso': {
                        'importe': amount, 'id_forma_pago': 1, 'pago_unico': True}}, 37)
                conn.rollback.assert_called_once()
                conn.commit.assert_not_called()

    @patch('services.call_service.obtener_conexion')
    def test_database_failure_rolls_back_call(self, connection):
        conn = connection.return_value
        conn.cursor.return_value.fetchone.side_effect = [(1,), (12,)]
        with patch('services.call_service.create_commitment', side_effect=RuntimeError('database failure')):
            with self.assertRaises(RuntimeError):
                register_call(8, {'resultado': 'PROMESA', 'compromiso': {}}, 37)
        conn.rollback.assert_called_once()
        conn.commit.assert_not_called()


if __name__ == '__main__':
    unittest.main()
