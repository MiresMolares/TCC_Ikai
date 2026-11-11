// ============================================================================
// CONTEÚDO NO BANCO DE DADOS (ESQUELETO COMENTADO)
// ============================================================================
//
// Este arquivo está TODO comentado de propósito: ele só funciona quando o
// banco de dados (e a API na frente dele) existir. Hoje o app usa
// `ConteudoLocal` (lib/services/conteudo_repositorio.dart), que guarda tudo no
// aparelho e permite testar artigos, comunidades e mensagens de ponta a ponta.
//
// PARA LIGAR O BANCO DE DADOS
//   1. Crie as tabelas/coleções abaixo e a API (ou use Supabase/Firebase e
//      adapte as chamadas http daqui para o SDK escolhido).
//   2. Descomente a classe `ConteudoRemoto` e o import de `http`.
//   3. Em lib/services/conteudo_usuario.dart, troque
//         ConteudoUsuarioService._(ConteudoLocal())
//      por
//         ConteudoUsuarioService._(ConteudoRemoto(baseUrl: '<sua api>'))
//   4. Nada mais muda: as telas só conhecem a interface `ConteudoRepositorio`.
//
// ----------------------------------------------------------------------------
// ESQUEMA SUGERIDO (SQL; em banco de documentos, uma coleção por tabela)
// ----------------------------------------------------------------------------
//
//   usuarios(id, email unique, nome, criado_em)           -- já existirá
//
//   artigos(
//     id            text primary key,
//     autor_id      text references usuarios(id) on delete cascade,
//     objetivo_id   text not null,       -- 'ver_conteudo' | 'ler' | 'estudar'
//     categoria_id  text not null,       -- ex.: 'ler_romance'
//     nivel         smallint check (nivel between 1 and 3),
//     titulo        text not null,       -- 5..100
//     resumo        text not null,       -- 10..200
//     tags          text[] not null,     -- até 5
//     paragrafos    text[] not null,     -- até 12000 caracteres no total
//     criado_em     timestamptz default now()
//   )
//
//   comunidades(
//     id            text primary key,
//     criador_id    text references usuarios(id) on delete cascade,
//     nome          text not null unique (lower(nome)),   -- 3..40
//     descricao     text not null,                        -- 10..140
//     icone_id      text not null,
//     categorias    text[] not null,                      -- 1..5
//     regras        text[] not null,                      -- até 6
//     criado_em     timestamptz default now()
//   )
//
//   posts(
//     id            text primary key,
//     comunidade_id text references comunidades(id) on delete cascade,
//     autor_id      text references usuarios(id) on delete cascade,
//     texto         text not null,                        -- 3..500
//     criado_em     timestamptz default now()
//   )
//
// REGRAS QUE O SERVIDOR PRECISA REPETIR (o app não é confiável):
//   - o autor vem do TOKEN de login, nunca do corpo da requisição;
//   - só o autor apaga o próprio artigo/post; só o criador apaga a comunidade
//     (e o criador também apaga mensagens dela);
//   - os mesmos limites de tamanho de ConteudoUsuarioService;
//   - remover emojis e validar categoria/objetivo contra a lista oficial;
//   - limite de frequência (por exemplo, 20 mensagens por hora por pessoa);
//   - o e-mail NUNCA é devolvido para outros usuários: só o primeiro nome.
//
// ----------------------------------------------------------------------------
// ROTAS ASSUMIDAS PELA CLASSE ABAIXO (REST + JSON)
// ----------------------------------------------------------------------------
//
//   GET    /artigos                       -> [artigo]
//   POST   /artigos                       corpo: artigo
//   DELETE /artigos/{id}
//   GET    /comunidades                   -> [comunidade]
//   POST   /comunidades                   corpo: comunidade
//   DELETE /comunidades/{id}              (apaga os posts junto)
//   GET    /comunidades/{id}/posts        -> [post], mais novos primeiro
//   POST   /comunidades/{id}/posts        corpo: post
//   DELETE /comunidades/{id}/posts/{postId}
//   DELETE /meus-dados                    (exclusão de conta)
//
// ----------------------------------------------------------------------------
// CÓDIGO (DESCOMENTE QUANDO A API EXISTIR)
// ----------------------------------------------------------------------------
//
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
//
// import '../data/artigo.dart';
// import '../data/comunidade.dart';
// import '../data/conteudo_json.dart';
// import 'conteudo_repositorio.dart';
//
// class ConteudoRemoto implements ConteudoRepositorio {
//   final String baseUrl;
//
//   /// Devolve o token de login da pessoa (vem do AuthService quando o login
//   /// também for no servidor).
//   final String? Function()? token;
//
//   final http.Client _http;
//
//   ConteudoRemoto({required this.baseUrl, this.token, http.Client? cliente})
//       : _http = cliente ?? http.Client();
//
//   Uri _u(String caminho) => Uri.parse('$baseUrl$caminho');
//
//   Map<String, String> get _cabecalhos => {
//         'Content-Type': 'application/json',
//         if (token?.call() != null) 'Authorization': 'Bearer ${token!()}',
//       };
//
//   Future<List<Object?>> _lista(String caminho) async {
//     final r = await _http.get(_u(caminho), headers: _cabecalhos);
//     if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
//     final d = jsonDecode(utf8.decode(r.bodyBytes));
//     return d is List ? d : const [];
//   }
//
//   Future<void> _enviar(String caminho, Object corpo) async {
//     final r = await _http.post(
//       _u(caminho),
//       headers: _cabecalhos,
//       body: jsonEncode(corpo),
//     );
//     if (r.statusCode < 200 || r.statusCode >= 300) {
//       throw Exception('HTTP ${r.statusCode}');
//     }
//   }
//
//   Future<void> _apagar(String caminho) async {
//     final r = await _http.delete(_u(caminho), headers: _cabecalhos);
//     if (r.statusCode < 200 || r.statusCode >= 300) {
//       throw Exception('HTTP ${r.statusCode}');
//     }
//   }
//
//   @override
//   Future<List<Artigo>> listarArtigos() async => [
//         for (final m in await _lista('/artigos'))
//           if (artigoDeMapa(m) != null) artigoDeMapa(m)!,
//       ];
//
//   @override
//   Future<void> salvarArtigo(Artigo artigo) =>
//       _enviar('/artigos', artigoParaMapa(artigo));
//
//   @override
//   Future<void> apagarArtigo(String id) => _apagar('/artigos/$id');
//
//   @override
//   Future<List<Comunidade>> listarComunidades() async => [
//         for (final m in await _lista('/comunidades'))
//           if (Comunidade.tentarLer(m) != null) Comunidade.tentarLer(m)!,
//       ];
//
//   @override
//   Future<void> salvarComunidade(Comunidade c) =>
//       _enviar('/comunidades', c.toMap());
//
//   @override
//   Future<void> apagarComunidade(String id) => _apagar('/comunidades/$id');
//
//   @override
//   Future<List<PostComunidade>> listarPosts(String comunidadeId) async => [
//         for (final m in await _lista('/comunidades/$comunidadeId/posts'))
//           if (PostComunidade.tentarLer(m) != null)
//             PostComunidade.tentarLer(m)!,
//       ];
//
//   @override
//   Future<void> salvarPost(PostComunidade p) =>
//       _enviar('/comunidades/${p.comunidadeId}/posts', p.toMap());
//
//   @override
//   Future<void> apagarPost(String comunidadeId, String postId) =>
//       _apagar('/comunidades/$comunidadeId/posts/$postId');
//
//   @override
//   Future<void> apagarDoAutor(String email) => _apagar('/meus-dados');
// }
