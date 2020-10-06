---LuaRSS Reader para TV Digital<br/>
--@author Manoel Campos da Silva Filho<br/> 
--Professor do Instituto Federal de Educação, Ciência e Tecnologia do Tocantins<br/>
--http://manoelcampos.com

require "tcp"

dofile("xml2lua/xml.lua")
dofile("xml2lua/handler.lua")

---Imprime uma tabela, de forma recursiva
--@param tb A tabela a ser impressa
--@param level Apenas usado internamente para 
--imprimir espaços para representar os níveis
--dentro da tabela.
function printable(tb, level)
  level = level or 1
  local spaces = string.rep(' ', level*2)
  for k,v in pairs(tb) do
      if type(v) ~= "table" then
         print(spaces .. k..'='..v)
      else
         print(spaces .. k)
         level = level + 1
         printable(v, level)
      end
  end  
end

---Número da notícia a ser exibida no momento
local itemIndex = -1

---Instancia o objeto que é responsável por
--armazenar o XML em forma de uma table lua
local xmlhandler = simpleTreeHandler()

---Retorna um novo índice de notícia a ser exibida.
--@param index Valor do índice da notícia atualmente exibida
--@param forward Se igual a true, incrementa o índice em 1,
--senão, decrementa em 1.
--@returns Retorna o novo índice da notícia a ser exibida.
function moveItemIndex(index, forward)
  --Se o index for menor que zero, é porque
  --o XML do feed ainda não foi baixado, logo,
  --não há notícia a ser exibida.
  if index < 0 then
     return index
  end
  
  if forward then
  	 index = index + 1
  	 if index > #xmlhandler.root.rss.channel.item then
  	    index = 1
  	 end
  else
  	 index = index - 1
  	 if index <= 0 then
  	    index = #xmlhandler.root.rss.channel.item
  	 end;
  end
  return index
end 

---Exibe uma notícia na tela
function showItem()
  --Se não existe uma posição inicializada (devido as notícias não
  --terem sido carregadas ainda), 
  --ou não existe nenhuma notícia no feed, sai
  if (itemIndex < 0)  or (#xmlhandler.root.rss.channel.item  == 0) then 
     return
  end
  
  local i = itemIndex
  local title = ""
  --Se o campo description é uma tabela, analisa seu conteúdo
  --para obter o texto da descrição da notícia
  if type(xmlhandler.root.rss.channel.item[i].description) == "table" then
     --Se a tabela está vazia, a descrição será o título da notícia
     if #xmlhandler.root.rss.channel.item[i].description == 0 then
        title = xmlhandler.root.rss.channel.item[i].title
     --senão, pega o valor do primeiro campo existente na tabela description
     else
        title = xmlhandler.root.rss.channel.item[i].description[1]
     end
  else
     --Se o campo description não é uma tabela, obtém o valor
     --dele, ou no caso de ser nil, obtem o campo title ou ""
  	 title = xmlhandler.root.rss.channel.item[i].description or 
             xmlhandler.root.rss.channel.item[i].title or ""
  end
                
  print("\tCategoria: ", xmlhandler.root.rss.channel.item[i].category)
  print("\tTitulo: ", xmlhandler.root.rss.channel.item[i].title)
  print("\tLink: ", xmlhandler.root.rss.channel.item[i].link)
  print("\tData: ", xmlhandler.root.rss.channel.item[i].pubDate)
  print("\t", title, "\n")

  --width e height do canvas atual
  local cw, ch = canvas:attrSize()
  
  canvas:attrColor(255, 255, 255, 255)
  --canvas:attrColor("white")
  canvas:drawRect("fill", 0, 0, cw, ch)
   
  canvas:attrColor("blue")
  canvas:attrFont("vera", 24)
  local cat = xmlhandler.root.rss.channel.item[i].category or 
     xmlhandler.root.rss.channel.title or 
     xmlhandler.root.rss.channel.description or ""
  cat = cat .. '  (' .. itemIndex ..' de '.. #xmlhandler.root.rss.channel.item ..')'
  canvas:drawText(5, 0, cat)
  
  canvas:attrColor("black")
  canvas:attrFont("vera", 22)
  --width e height de um caractere maiúsculo
  local tw, th = canvas:measureText("a")
  
  --total de caracteres a serem exibidos por linha, dentro
  --da largura do canvas
  local charsByLine = tonumber(string.format("%d", cw / tw))
  
  local desc = title
  
  print("title", xmlhandler.root.rss.channel.item[i].title)
  
  --Quebra o texto da notícia em diversas linhas, 
  --gerando uma tabela onde cada item é uma linha que
  --foi quebrada. Isto é usado para que o texto seja
  --exibido sem sair da tela. 
  local desctb = breakString(desc, charsByLine)
  local y = 30
  --Percorre a tabela gerada a partir da quebra do texto 
  --em linhas, e imprime cada linha na tela 
  for k,ln in pairs(desctb) do
      canvas:drawText(5, y, ln)
      y = y + th + 4
  end
  
  local imgFechar = canvas:new("media/fechar.png")
  local imw, imh = imgFechar:attrSize()
  canvas:compose(cw-imw, ch-imh, imgFechar)
  
  local imgEsq = canvas:new("media/esq.png")
  local imw, imh = imgEsq:attrSize()
  canvas:compose(cw-imw*2, 0, imgEsq)
  local imgDir = canvas:new("media/dir.png")
  canvas:compose(cw-imw, 0, imgDir)
  
  canvas:flush()
  
  --Variável que aponta para uma função
  --utilizada para interromper
  --o avanço automático de notícias
  --quando o usuário pressiona uma 
  --tecla e assim, reiniciar
  --a contagem de tempo.
  if cancelTimerFunc then
	   cancelTimerFunc() --cancela o timer anteriormente criado
  end
  cancelTimerFunc = event.timer(8000, autoForward)
end

---Avança para a próxima notícia.
--Função utilizada para fazer o 
--avanço automático para a próxima notícia
--depois de um determinado tempo. 
function autoForward()
	itemIndex = moveItemIndex(itemIndex, true)
	showItem()  
end

---Quebra uma string para que a mesma tenha linhas
--com um comprimento máximo definido, não quebrando
--a mesma no meio das palavras.
--@param str String a ser quebrada
--@param maxLineSize Quantidade máxima de caracteres por linha
--@returns Retorna uma tabela onde cada item é uma linha
--da string quebrada.
function breakString(str, maxLineSize)
  local t = {}
  local i, fim, countLns = 1, 0, 0

  if (str == nil) or (str == "") then
     return t
  end 

  str = string.gsub(str, "\n", " ")
  str = string.gsub(str, "\r", " ")
    
  while i < #str do
     countLns = countLns + 1
     if i > #str then
        t[countLns] = str
        i = #str 
     else
        fim = i+maxLineSize-1
        if fim > #str then
           fim = #str
        else
	        --se o caracter onde a string deve ser quebrada
	        --não for um espaço, procura o próximo espaço
	        if string.byte(str, fim) ~= 32 then
	           fim = string.find(str, ' ', fim)
	           if fim == nil then
	              fim = #str
	           end
	        end
        end
        t[countLns]=string.sub(str, i, fim)
        i=fim+1
     end
  end
  
  return t
end

---Nome do arquivo XML contendo o feed RSS.
--Usado apenas para depuração, em ambientes de teste.
local FILE_NAME = "rss.xml"

---Desenha os componentes gráficos da aplicação
--@param xmltext String contendo o código XML de um feed RSS
function drawApplication(xmltext)
	  --Instancia o objeto que faz o parser do XML para uma table lua.
	  --O xmlhandler foi instanciado lá no início do código 
	  local xmlparser = xmlParser(xmlhandler)
	  xmlparser:parse(xmltext)
	  --printable(handler.root)
	  
	  --Se nenhuma notícia foi obtida, limpa a tela e sai
	  if xmlhandler.root.rss == nil then
	     canvas:clear()
	     canvas:flush()
	     return
	  end
	  
	  print("Nome do canal:\t",  xmlhandler.root.rss.channel.title)
	  print("Descricao:\t", xmlhandler.root.rss.channel.description)
	  print("Link:\t\t", xmlhandler.root.rss.channel.link)
	  print("Idioma:\t\t", xmlhandler.root.rss.channel.language)
	  print("Copyright:\t\t", xmlhandler.root.rss.channel.copyright)
	  if xmlhandler.root.rss.channel.image ~= nil then
	     print("Imagem:\t\t", xmlhandler.root.rss.channel.image.url)
	     if xmlhandler.root.rss.channel.image.width then
	       print(xmlhandler.root.rss.channel.image.width .. "x" .. 
	       xmlhandler.root.rss.channel.image.height)
	     end
	  end
	  print("Total de itens:\t", #xmlhandler.root.rss.channel.item)
	  itemIndex = 1
	  showItem()	  
end


---Escreve um texto na parte inferior da área do canvas lua
--@param text Texto a ser escrito
function writeText(text)
   canvas:attrColor(255,255,255,0)
   canvas:clear();
   
   local cw, ch = canvas:attrSize()
   
   canvas:attrFont("vera", 24)
   local tw, th = canvas:measureText("A")
   canvas:drawText(5, ch-th, text)
   canvas:flush()
end


---Função para converter uma string para o formato URL-Encode,
--também chamado de Percent Encode, segundo RFC 3986.
--Fonte: http://www.lua.org/pil/20.3.html
--@param s String a ser codificada
--@returns Returna a string codificada
function escape (s)
  s = string.gsub(s, "([&=+%c])", function (c)
        return string.format("%%%02X", string.byte(c))
      end)
  s = string.gsub(s, " ", "+")
  return s
end


---Cria um arquivo com o conteúdo informado em text.
--Se o arquivo já existir, substitui.
--Função utilizada apenas para depuração, uma vez que o módulo
--io de Lua  não está disponível no Ginga
--@param text Texto a ser adicionado no arquivo
--@param fileName Nome do arquivo a ser gerado.
function createFile(text, fileName)
    file, err = io.open (fileName, "w+")
    if file == nil then
    	print("Erro ao abrir arquivo "..fileName.."\n".. err)
    	return false
    else
    	print("Arquivo", fileName, "aberto com sucesso")
        file:write(text)
        file:close()
        return true
    end
end

---Função tratadora de eventos
--@param evt Tabela contendo dados sobre o evento disparado
function handler(evt)
   if (evt.class == 'key' and evt.type == 'press') then
	  print("key:", evt.key)
	  local ok = false
      --Se a tecla pressionada foi a seta para direita ou esquerda,
      --altera o índice da notícia a ser exibida.
      --Implementa uma "lista circular" para exibição das notícias.
	  if evt.key == "CURSOR_RIGHT" then
	     ok = true
	     itemIndex = moveItemIndex(itemIndex, true)
	  elseif evt.key == "CURSOR_LEFT" then
	     ok = true
	     itemIndex = moveItemIndex(itemIndex, false)
	  end
	  
	  if ok then
	     showItem()
	  --[[
      elseif evt.key == "RED" or evt.key == "r" or evt.key == "R" then
	     print("key1: RED")
	     evt.class = "ncl"
	     evt.type = "presentation"
	     evt.area = "fechar"
	     evt.action = "start"; event.post(evt)
	     evt.action = "stop";  event.post(evt)
	     return
	  ]]--
	  end
   end	 

	--Só executa o código depois do if se a aplicação
	--está inicializando, para baixar o XML do feed
	--e iniciar a exibição das notícias.
    if (evt.class == "ncl" and evt.type=="presentation" 
    and evt.action == "start") == false then
       return
    end
    
    --[[
    Para obter notícias de outro feed, altere as variáveis host e path. 
    Alguns servidores, como o g1.globo.com, 
    requerem que a requisição HTTP inclua a URL completa (http:// + host + path). 
    Servidores como do R7 funcionam tanto contendo apenas o path como a 
    URL completa na requisição. Aparentemente, todos suportam a URL
    completa, que pode ser usada como padrão, para não necessitar 
    criar regras para servidores diferentes. 

    Uma forma simples de testar se a requisição para um determinado servidor 
    está correta é usar telnet:    
    Se estiver tendo problemas com a obtenção do XML de algum
    servidor, use telnet a partir de um terminal:
  	telnet servidor.com.br 80
  	GET /endereco/do/arquivo/xml HTTP/1.0 (pressione dois enter)
  	ou
  	telnet servidor.com.br 80
  	GET http://servidor.com.br/endereco/do/arquivo/xml HTTP/1.0 (pressione dois enter)
  	em seguida, analise o resultado exibido.
  	--]]
    
    
    --Nome do servidor
    --local host = "g1.globo.com"
    local host = "www.r7.com"
    --local host = "rss.noticias.uol.com.br"
    
    --Endereço do arquivo XML do feed RSS dentro do servidor.
    --Ele deve ser convertido para o formato URL-Encode,
    --também conhecido como Percent Encode, conforme RFC 3986
    --local path = escape("/Rss2/0,,AS0-5598,00.xml") --globo
    local path = escape("/data/rss/brasil.xml") --r7
    --local path = escape("/ultimas-noticias/index.xml") --uol    
    
    print(evt.name, evt.value)
    
    tcp.execute(
        function ()
            writeText("Buscando notícias na internet...")
            tcp.connect(host, 80)
            --conecta no servidor
            print("Conectado a "..host)
            
            local url = "http://"..host..path
            local request = "GET "..url.." HTTP/1.0\n"
            --O uso de Host na requisição é necessário
            --para tratar redirecionamentos informados 
            --pelo servidor (código HTTP como 301 e 302)
            request = request .. "Host: "..host.."\n\n"
            print("request: "..request)
            --envia uma requisição HTTP para obter o arquivo XML do feed RSS
            tcp.send(request)
           	
           	--obtém todo o conteúdo do arquivo XML solicitado
            local result = tcp.receive("*a")
            if result then
                --Como a resposta da requisição será um arquivo XML,
                --e essa resposta conterá um cabeçalho HTTP,
                --é preciso remover esse cabeçalho e salvar
                --apenas o conteúdo XML válido. Este inicia em um sinal <
                local i = string.find(result, "?xml version=")
                if i then
                   result = string.sub(result, i-1, #result)
                end
            	--salva o arquivo XML recebido
    		    	print("Dados da conexao TCP recebidos")
              --Após ter baixado o arquivo XML, contendo o feed RSS,
              --desenha a interface da aplicação para iniciar
              --a exibir as notícias
              drawApplication(result)
		    else
            	print("Erro ao receber dados da conexao TCP")
            	if evt.error ~= nil then 
		        	result = 'error: ' .. evt.error
		        end
	        end
	        
            tcp.disconnect()
        end
    )    
end

event.register(handler)
