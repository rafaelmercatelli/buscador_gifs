import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:transparent_image/transparent_image.dart';

import 'gif_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _search;
  int _offset = 0;

  Future<Map> _getGifs() async {
    http.Response response;
    //se o search for nulo pegar os trendigs gifs
    if (_search == null || _search.isEmpty) {
      response =
          await http.get("https://api.giphy.com/v1/gifs/trending?api_key="
              "MZHtPXhbGM8vaqEHg9aqWdF8KxEescWq&limit=20&rating=g");
      //senao usar o texto do search digitado
    } else {
      response = await http.get("https://api.giphy.com/v1/gifs/search?api_key="
          "MZHtPXhbGM8vaqEHg9aqWdF8KxEescWq&q=$_search&limit=19&offset=$_offset&rating=g&lang=en");
    }
    //snapshot?
    return json.decode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        //Image.network como titulo pode carregar gifs
        title: Image.network(
            "https://developers.giphy.com/static/img/dev-logo-lg.7404c00322a8.gif"),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              //botao enter do teclado, vai pegar o texto
              onSubmitted: (text) {
                //dar um setState mudando o parametro _search para o texto digitado
                setState(() {
                  _search = text;
                  //resetando o offset para ele mostrar os novos itens em pesquisas novas
                  _offset = 0;
                });
              },
              decoration: InputDecoration(
                labelText: "Pesquise aqui",
                labelStyle: TextStyle(
                  color: Colors.white,
                ),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            //FutureBuilder builda um Widget com algo de uma chamada do tipo future
            //entao precisa passar qual chamada vai ter os dados (no caso getGifs) e depois o snapshot
            //para o builder buildar
            child: FutureBuilder(
              //snapshot vem do getGifs...?
              future: _getGifs(),
              builder: (context, snapshot) {
                //verificando a conexao do snapshot para colocar o loading
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return Container(
                      width: 200.0,
                      height: 200.0,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 5.0,
                      ),
                    );
                  default:
                    if (snapshot.hasError)
                      return Container();
                    else
                      return _createGifTable(context, snapshot);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  //metodo para ver se mostra 20 itens sem pesquisa ou 21 para deixar um espaço em branco para adicionar o "botao" carregar mais
  int _getCount(List data) {
    if (_search == null) {
      return data.length;
    } else {
      return data.length + 1;
    }
  }

  Widget _createGifTable(BuildContext context, AsyncSnapshot snapshot) {
    return GridView.builder(
        padding: EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: _getCount(snapshot.data["data"]),
        //builder que constroi ITEM A ITEM do grid
        itemBuilder: (context, index) {
          //se eu nao estiver pesquisando OU se eu estiver pesquisando mas ESTE item nao for o ultimo
          if (_search == null || index < snapshot.data["data"].length)
            return GestureDetector(
              //ao toque abrir a outra pagina q mostra o giff
              onTap: () {
                Navigator.push(
                    context,
                    //passando o snapshot pelo construtor com os dados do gif da vez
                    MaterialPageRoute(
                        builder: (context) =>
                            GifPage(snapshot.data["data"][index])));
              },
              onLongPress: () {
                Share.share(snapshot.data["data"][index]["images"]
                    ["fixed_height"]["url"]);
              },
              //FadeInImage para as imagens aparecerem aos poucos
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: snapshot.data["data"][index]["images"]["fixed_height"]
                    ["url"],
                height: 300.0,
                fit: BoxFit.cover,
              ),
            );
          else
            //se for uma pesquisa ou se for o ultimo item, mostrar o add para carregar mais itens
            return Container(
              child: GestureDetector(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 70.0,
                      ),
                      Text(
                        "Carregar mais...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                        ),
                      ),
                    ],
                  ),
                  //ao clicar no carregar mais, mudar o offset para chamar mais itens na api
                  onTap: () {
                    setState(() {
                      _offset += 19;
                    });
                  }),
            );
        });
  }
}
