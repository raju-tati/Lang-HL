# Lang-HL
HL progarmming language

## Example
```
class Main {
    (JSON,
     !mechanize = WWW::Mechanize.new());
 
    function main() {
        class.counter = 0;
 
        var hash = class.returnNumber();
        var json = encode_json(hash);
        print(json, "\n");
 
        var url = "https://metacpan.org/pod/WWW::Mechanize";
        !mechanize.get(url);
        var page = !mechanize.text();
        print(page, "\n");
    }
 
    function returnNumber() {
        var number = {};
 
        if(class.counter < 10) {
           class.counter = class.counter + 1;
 
           number = { "number" : class.returnNumber() };
           return number;
        }
 
        return class.counter;
    }
}
```
