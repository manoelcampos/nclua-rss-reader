NCLua RSS Reader
----------------
[![](media/rss_goodies.png)](media/rss_goodies.png)Com a possibilidade de se ter internet a partir da TV, por meio de um cabo de rede conectado do Set-top Box a um modem ADSL, ou por qualquer outro tipo de conexão, uma aplicação que pode ser muito útil e conveniente de se ver na tela da TV é o famoso leitor de RSS, para que o telespectador possa ver notícias sentado no sofá da sala.

Com este objetivo, estou disponibilizando uma aplicação deste tipo. A aplicação NCLua RSS Reader foi desenvolvido em NCLua. Ela exibe notícias da intenet, a partir de um feed RSS. O arquivo XML do feed é baixado diretamente de um site e as notícias são exibidas na tela. Elas são exibidas uma após a outra, de forma automática. O usuário ainda pode usar as setas do controle remoto para avançar ou retroceder. O botão vermelho pode ser usado para fechar a aplicação. 

[Para download do arquivo XML, foi utilizada a classe TCP, disponibilizada aqui](http://www.telemidia.puc-rio.br/~francisco/nclua/tutorial/index.html). Uma grande dificuldade que tive, em relação à aplicação anterior, o [Sistema de Enquete](http://manoelcampos.com/2009/12/04/aplicacao-de-enquete-para-tv-digital-utilizando-canal-de-retorno/), foi que, segundo o que li sobre o protocolo HTTP, no final da mensagem de requisição é necessário haver uma quebra de linha (n). Porém, para obtenção do XML a partir de um servidor Web, só funcionou com duas quebras de linha. Só descobri isso depois de fazer as requisições HTTP na mão, usando telnet. Assim, pode ser que muitas das dificuldades relatadas sobre o uso da classe TCP, sejam por falta de um n a mais no final da mensagem HTTP.

Ah, não esqueça de configurar a interface de rede do VMWare player para o modo Bridge, senão, pode não funcionar. [Veja como fazer isso aqui](http://manoelcampos.com/2009/12/04/aplicacao-de-enquete-para-tv-digital-utilizando-canal-de-retorno/).

Se o feed RSS possuir formatação HTML, o sistema não renderizará a mesma, pois para isso precisaria salvar de cada notícia para um arquivo HTML, mas não quis me preocupar com isso.

O processamento do arquivo XML foi feito utilizando-se o [Lua XML Parser](https://github.com/manoelcampos/LuaXML). O parser gera uma table em Lua, a partir do código XML, tornando bem simples a tarefa de recuperar os valores do XML. Porém, o código apresentado lá não compila em Lua 5.x. Assim, nos fontes da aplicação tem todo o código adaptado para Lua 5.x. O [Johnny Moreira Gomes fez um tutorial](http://www.ufjf.br/lapic/files/2010/04/Tutorial_Lua_XML_Parser1.pdf) mostrando como usar a biblioteca LuaXML, também disponível [aqui](tutorial_lua_xml_parser.pdf).

A URL do arquivo XML do feed está hard coded na aplicação. Assim, para obter notícias de outro feed, abra o código fonte e altere as variáveis host e uri. Alguns servidores, como o g1.globo.com, requerem que a requisição HTTP inclua a URL completa (host + uri). Servidores como do R7 funcionam tanto contendo apenas a URI como a URL completa na requisição. Aparentemente, todos suportam a URL completa, que pode ser usado como padrão, para não necessitar criar regras para servidores diferentes. Outros, como o do UOL, necessitam que sejam implementado o redirecionamento de URL's. Quando uma requisição é feita para um endereço que mudou, é necessário tratar a mensagem, que contém o novo endereço. 

Uma forma simples de testar se a requisição para um determinado servidor está correta é usar telnet:

```bash
telnet servidor.com.br 80
GET http://servidor.com.br/endereco/do/arquivo/xml HTTP/1.1 (Pressione enter)
Host: servidor.com.br (Pressione dois enter)
```

O código está todo comentado para facilitar o entendimento. [O vídeo disponibilizado tem licença Creative Commons e foi obtido aqui](http://creativecommons.org/videos/wanna-work-together). [As imagens das setas foram obtidas aqui, e são de domínio público](http://www.public-domain-photos.com/free-cliparts/shapes/arrows/arrow_shape_jeff_walden_-5198.htm). [A imagem "Fechar" foi gerada a partir da ferramenta web livremente disponível aqui](http://pt.cooltext.com/Buttons).

Uma restrição da aplicação, é que se o feed possuir mais de um canal (channel), apenas o primeiro será analisado, porém, isto é bem simples de ser melhorado.


Pré-Requisitos
--------------

É recomendado a utilização do [Ginga Virtual STB 0.11.2 rev 23 ou superior](http://gingancl.org.br). A versão anterior do Ginga VSTB possuia algumas dificuldades para acesso à rede a partir da VM, normalmente necessitando de configurações na interface de rede da mesma.

Antes de usar a aplicação na VM, verifique se a mesma está acessando a rede local/internet (usando ping, telnet, wget, curl ou qualquer comando similar). Para isto, fundamentalmente, na tela inicial da VM deve ser exibido o IP da mesma. Caso não esteja conseguindo acesso à rede, tente alterar o modo da interface de rede da VM de bridge para NAT ou vice-versa (é necessário reiniciar a VM após tal alteração).


Licença
-------

O projeto é licenciado sob a [Creative Commons Atribuição-NãoComercial-CompartilhaIgual 2.5 Brasil (CC BY-NC-SA 2.5 BR)](http://creativecommons.org/licenses/by-nc-sa/2.5/br/)
