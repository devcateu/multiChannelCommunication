## Ograniczenia i sposoby komunikacji z chaincodami w HyperledgerFabric

### Komunkacja z HLF

Blockchainy takie jak Hyperledger Fabric umożliwiają wgrywanie SmartContract. Dzięki nim możemy wykonywać logikę biznesową i być pewnym, że na blockchainie. 
Otwiera to możliwość walidacji oraz upewnienia się, że organizacje które współdzielą network pracują na tej samej wersji danych. 

W tym artykule pokażę ukazać w jaki sposob można wywoływać kontrakty na prywatnym blockchainie Hyperledger Fabric. 
Dodatkowo przedstawie jaki wpływ na konsystencje danych ma wywoływanie kontraktów na tym samym jak i na różnym channellu.

### Kilka słówek z HLF - chyba do wywalenia

Jeżeli znasz już HLF możesz śmiało pominąć ten akapit.

Dla tych, którzy nie czują się jeszcze komfortowo z HLF przedstawię kilka pojęć ze świata HLF, które pomogą zrozumieć artykuł. Pamiętajcie jednak, że są to pobieżne definicje, za każdym z nich kryje się ogromna logika i każde zasługuje na osobny artykuł ;) Pojęcia prezentuje w formie listy aby łatwo było wrócić ;)

* Channel - jest to lańcuch bloków
* Network - set of channels
* Chaincode - jest tym samym co w Ethereum smart contract, czyli kodem programu wykonywanym bezpośrednio na bloku.  
* peer - serwis, do którego wgrywa się Chaincode. 
* orderer - serwis, zatwierdzający transakcje
* CA - serwis odpowiedzialny za autentykacje użytkowników, trzyma ich certyfikaty.

### Opis środowiska

/**
W artykule wielokrotnie będzie pojawiały się snippety kodu oraz odniesienia do skryptów. Są one dostępne na moim GH.
Wymaganiem jest posiadanie na PATH ścieżki do narzędzi HyperledgerFabirc: cryptogen oraz configtxgen oraz jednocześnie zainstalowanego docker i docker-compose. 
*/


Nasz network składa się z 4 organizacji. Pierwsza organizacja, `orderer.com` posiada jednego orderera. Pozostałe 3 organizacje, `org1`, `org2` oraz `org3` posaidają po 1 perze.
W networku są zainstalowane 2 channele. Pierwszy z nich nazywa się channelAll i jak nazwa wskazuje należą do niego wszystkie organizacje.
Drugi nazywa się channel12 i jak nazwa wskazuje należą do niego tylko organizacje 1 i 2. Na obu zainicjalizowany jest chaincode `ring` a dodatkowo na channelAll mamy zainicjalizowany chaincode `zing`.
Chaincody `ring` zainstalowany jest na wszystkich peer-ach. Podczas, gdy `zing` tylko na peerach organizacji `org1` oraz `org3`. 
Wszystkie chaincody zostały zainicjalizowane w taki sposób, że wystarczy potwierdzenia transakcji od dowolnego peer aby została ona wysłana do orderera, a następnie rozprapogowana do wszystkich peerów.

### First  <strike>blood</strike> request  

Oba Nasze chaincody pochodzą z tego samego źródła. Dla uproszczenia nie posiadają one żadnej logiki biznesowej. Są one KeyValue store, z pewnymi dodatkowymi modyfikacjami o których będę pisał w kolejnych akapitach.
Pomimo braku logiki biznesowej taka prosta baza pozwoli ukazać wiele przypadków użycia.  

Jako pierwsze popatrzmy na wywołanie chaincodu `ring`. Najpierw zapisujemy dane wywołując   

```
01_simplePutData.sh linia 3
```
 
Następnie na peerze org3 możemy dostać spowrotem dane, które zostały zapisane.
```
https://gist.github.com/devcateu/856fc0ada9c509e3fab8e4489e77ec3c
```
Powyższe wywolanie generuje następujący rezultat: 
```
Result for first is 123
```
Możemy tak zrobić poniewać wywołanie invoke spowoduje, że zostanie wysłany ProposalRequest do org1 Peer. Następnie ProposalResponse zostanie opakowany w TransactionRequest i przekazany do orderera, ktory to rozpropaguje wynik transakcji do wszystkich peerów.


Jeśli jednak na tym samym channellu, ale dla innego Chaincode wywołamy zapytanie:
```
01_simplePutData.sh linia 6
```
To w rezultacie otrzymamy
```
NO RESULT FOR KEY
```
Taka sama sytucja będzie mieć miejsce w przypadku zapytania tego samego chaincode ale na innym channelu
```
01_simplePutData.sh linia 7
```

Jak widać oba chaincody pomimo przechowywania danych pod jednym kluczem nie dzielą domyślnie stanu. 
Dzieje się tak ponieważ dla każdego zainstalowanego chaincodu w channelu istnieje osobna baza. Można to sprawdzić wchodząc w przeglądarkę na couchDB:
![alt text](images/CouchDB_databases.png "Created databases in CouchDB")
/**
http://localhost:5984/_utils/#/_all_dbs
*/
 
### Komunikacja między chaincodami 

Hyperledger Fabric pozwala na wywoływanie chaincodów ze sródka innego chaincoda. Do tego celu wykorzystywana jest metoda `stub.invokeChaincode`. Aby pokazać jak ona działa dodałem ją w funkcjach: `getFrom` oraz `putHereAndTo`. 
Pierwsza z nich pobiera wartość z innego chaincodu lub/i channelu. `putHereAndTo` natomiast zapisuje dane do wskazanego chaincodu i channelu. Ich implementacje możecie zobaczyć poniżej: 
```
KeyValueContract.ts  44-55
```

Na początek sprawdzimy jak działa zapytywanie o dane chaincodów na tym sammym jak i na innym channelu:
```
02_takeValueFromOtherChaincode.sh
``` 
W obu wypadkach dostaliśmy rezutltat:
```
Result for second is 1000
```
Czyli działa i jesteśmy wstanie pobierać dane z innych chaincodów.

Teraz sprawdźmy jak zachowa się zapisywanie danych. Najpierw kiedy wywołujemy zapisanie na tym samym channellu ale innym chaincodzie.
```
03_putValueToOtherChaincodel.sh
```
Po wywołaniu dostajemy rezultat:
```
Chaincode invoke successful. result: status:200 payload:"Result local: \"OK\" ; result remote: \"OK\""
From RING:
Result for third is 9458
From ZING:
Result for third is 9458

```
Czyli z tego wynika, że w ramach jednego channelu jesteśmy wstanie wywołać inny channel w celu zapisania na nim danych.

Teraz zobaczmy co się wydarzy kiedy w podobny sposób będziemy chcieli zapisać dane na innym channellu.
```
04_putValueToOtherChannel.sh
``` 
Wynik:
```
Chaincode invoke successful. result: status:200 payload:"Result local: \"OK\" ; result remote: \"OK\"" 
ChannelAll:
Result for fourth is 3215
Channel12:
NO RESULT FOR fourth
```
Jak widzimy w pierwszej linijce powyżej zapis do drugiego channellu zakończyl się zwróceniem statusu OK. Jednak kiedy pytamy o wartość dostajemy odpowiedź, że wartość na Channel12 nie zostala zapisana, dlaczego?
Ano metoda `stub.invokeChaincode` działa w taki sposób, że pozwala zapytać o dane dowolnego channellu. Natomiast żądania zapisu mają swoj efekt tylko na channellu, który zainicjalizował wywołanie. 
Można się domyślać, że ta metoda działa w taki sposob ponieważ rezultat zatwierdzony przez orderera musi zostać zapisany w całości albo w cale. Tymczasem każdy channel posiada swój blockchain, 
więc orderer nie jest wstanie zapewnić spójności danych między channelami, gdyż każdy zapisuje transakcje do osobnego bloku. 

W tej sekcji chciałbym zaprezentować jeszcze jedną sytuację. org2 należy zarówno do `channelAll` oraz do `channel12`. Nie posiada on natomiast zainstalowanego chaincoda `zing`. Co stanie się kiedy będziemy próbować pobrać dane z tego chaincoda?
```
05_takeValueFromOtherChaincodeButPeerDoesNotHaveContract.sh
```
Rezultat:
```
Chaincode invoke successful. result: status:200 payload:"OK" 
Error: endorsement failure during query. response: status:500 message:"transaction returned with failure: Error: INVOKE_CHAINCODE failed: transaction ID: f6ab6dbd747ddf25ebfe158eea5a9b0b7478d6a031b66a08a4f3c2f02fe2f7fe: cannot retrieve package for chaincode zing/1.0, error open /var/hyperledger/production/chaincodes/zing.1.0: no such file or directory" 
```
Jak można było się domyśleć zapytanie zakończy się błędem. Jeżeli Nasz chaincode X wywołuje inny chaincode Y to chaincode Y powinien być zainstalowany na tych samych peerach co chaincode X. W przeciwnym wypadku możemy spotkać się z wyjątkiem takim jak powyżej. 

### Niedeterministyczne rezultaty

Hyperledger Fabric gwarantuje, że dane zapisane na blockchainie są niemutowalne. Ponadto w momencie zapisywania danych sprawdza, że transakcja przeszła akceptacje odpowiedniej ilości peeróe. 
Innymi słowy spełniła endorsment policy. Często zdarze się, że wymagana jest aby większość organizacji należących do kanałau albo czasem nawet wszystkie zatwierdziły modyfikacje przy użyciu danego chaincoda.
W tym celu podczas wywoływania chaincoda podaje się listę peerów do których ma trafić żądanie. Pomimo, że Nasze chaincody zostały uruchomione z polityką, 
że wystarczy iż tylko jeden peer jest wstanie wykonać zapis danych to nadal możemy wywołać go jak gdyby była potrzebna większa ilość.
```
06_simplePutDataToAllPeers.sh
```
Wynik:
```
Chaincode invoke successful. result: status:200 payload:"OK" 
Result for sixth is 666
```
Ponieważ chaincode może być pisany w nodejs,Go albo Javie stawia to przed autorem szereg możliwości. Może on na przykład wywołać żądanie Http. 
W zależności co jest celem takiego wywołania może skutkować, że nawet 2 żądania HTTP w małej odległości czasowej mogą zwrócić różne rezultaty. 
Tutaj chciałbym pokazać na przykładzie pobieranie czasu systemowego co może się zdarzyć jeżeli peery operują na różnych wartościach.

Wprowadźmy najpierw 2 funkcje:
```
KeyValueContract.ts 20-30
```
`putTime` zapisuje, obecny czas w millisekundach. Podczas gdy druga zapisuje wartość otrzymaną w parametrach, zwraca natomiast czas w millisekundach.

Sprawdźmy jak zachowa się wywołanie dla `putTime`:
```
07_putTime.sh
```
Wynik:
```
Error: could not assemble transaction: ProposalResponsePayloads do not match - proposal response:.... 
NO RESULT FOR seventh
```

A teraz dla `putValueAndReturnTime`:
```
08_putValueAndReturnTime.sh
```
Wynik:
```
Error: could not assemble transaction: ProposalResponsePayloads do not match - proposal response: ... 
NO RESULT FOR eighth
```

Jak widzimy wywołania, które zwracają albo zapisują różne rezultaty powodują, że transakcja kończy się niepowodzeniem. Jeżeli z jakiegoś powodu chciałbyś użyć w swoim chaincodzie czasu
to można użyć ```ctx.stub.getTxTimestamp()```, czyli czasu w którym została zapoczątkowana transakcja. Jest to wartość stała dla każdego peera. Transakcja nie przechodzi, ponieważ orderer po
otrzymaniu żądania transakcji sprawdza czy wszystkie odpowiedzi i wartości zapisane przez peery są takie same. W przypadku, gdy którakolwiek się różni cała transakcja jest odrzucana.

Wracając jednak do żądań Http. Na podstawie powyższych doświadczeń sugeruję, aby dane które pobierane są poprzez wywołania HTTP nie były często modyfikowane, 
dzięki czemu będzie mniejsze prawdopodobieństwo zakończenia działania chaincoda błędem. Moim zdaniem najlepszym wyjściem jest całkowite niekorzystanie z żądań HTTP oraz innych nieterministycznych wywołań. 
Niech rezultat działania peer-a zależy wyłącznie od stanu w blockchainie oraz parametrów wejściowych funkcji.

## TODO
jeżeli, któraś z modyfikowanych wartości zmieniła się między wywołaniem peer-a a zatwierdzeniem transakcji przez orderera. Transakcja jest odrzucana.
jeżeli transakcja modyfikuje dane, ale jednocześnie woła inny chaincode o dane i dane na tym innym chaincodzie zostaną zmodyfikowane cała. Transakcja jest odrzucana.

### Last Force

Na koniec przyjrzyjmy się jeszcze kodowi poniżej:
```
09_getWithoutFullContractName.sh
```
Jak widzimy jest to nic nadzwyczajnego. Dodajemy wartość a następnie ją pobieramy. Co ciekawe niepodajemy pelnej ścieżki do chaincoda, a tylko nazwę funkcji. 
```
Chaincode invoke successful. result: status:200 payload:"OK" 
Agent see that KeyValueContract should return Result for ninth is Frankenstein
Result for ninth is Frankenstein
```
Jak się okazauje takie wywołanie powoduje, że do rezultatu jest dopisywany dodatkowy tekst. Dlaczego? Tak naprawdę każdy chaincode zawiera 2 kontrakty:
KeyValueContract oraz AgentContract. Oba posiadają metodę `get`, także w rezultacie wywołania powyżej bez podania pelnej ścieżki do kontraktu i metody jest wywolywana ta z AgentContract.
Stało się tak ponieważ w pliku `src/index.ts` AgentContract został zdefiniowany jako pierwszy. Jeżeli nie podamy pełnej ścieżki do metody zostanie wywołana pierwsza metoda o takiej nazwie. 
Warto tutaj nadmienić, że jeden kontrakt nie może posiadać 2 metod o takiej samej nazwie. Lista parametrów nie rozróżnia konkretnej metody, a jedynie jej nazwa. 


### Podsumowanie

Programowanie chaincodow w HyperledgerFabric to potężna broń w rękach Developera. Można pisać przy ich użyciu tworzyć złożoną logikę dzięki wywołaniom innych kontraktow oraz wykorzystywać moc języków, które zlużą do pisania kontraktów. 
Należy jednak przy tym jednak pamiętać, że nie wsyzstkie operacje są możliwe,jak wspomniane zapisywanie między channelami oraz działania niederministyczne.  

