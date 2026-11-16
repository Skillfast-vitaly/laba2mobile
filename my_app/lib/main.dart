import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main(){
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});
 @override
 Widget build(BuildContext context){
   return const MaterialApp(
    debugShowCheckedModeBanner:false,
      home:Home(),
   );
 }
}

class Home extends StatefulWidget{
 const Home({super.key});
 @override
 State<Home> createState(){return _HomeState();}
}

class _HomeState extends State<Home> {
 final c=TextEditingController();
 Repo rep=Repo();
 List<String> list=['EUR','RUB','USD','GBP','CNY','KZT','VND','THB'];
 List<String> hist=[];
 String a='EUR', b='RUB';
 String err='';
 double rez=0;
 Rate k=Rate(0,'','');
 bool load=false,ok=false;

 void swap(){
   setState((){
    String t=a;
     a=b;
    b=t;
    ok=false;err='';
   });
 }

 Future<void> calc()async{
   String s=c.text.trim().replaceAll(',','.');
   setState((){err='';ok=false;});

   if(s==''){
    setState((){err='Введите сумму';});
      return;
   }
   double? n=double.tryParse(s);
    if(n==null){
     setState(() {err='Введите число';});
     return;
    }
   if(n<0){
     setState((){err='Сумма не может быть отрицательной';});
    return;
   }
    if(a==b){
     setState((){err='Выберите разные валюты';});
     return;
    }

   FocusScope.of(context).unfocus();
   setState((){load=true;});
   try {
     Rate v=await rep.get(a,b);
      double x=n*v.v;

     String line=n.toStringAsFixed(2)+' '+a+' → '+x.toStringAsFixed(2)+' '+b;
     setState((){
       k=v;
        rez=x;
       ok=true;
       load=false;
        hist.insert(0,line);
       if(hist.length>5){hist.removeLast();}
     });
   }catch(e){
     setState(() {
      err=e.toString().replaceAll('Exception: ','');
       load=false;
     });
   }
 }

 List<DropdownMenuItem<String>> items(){
   List<DropdownMenuItem<String>> l=[];
   for(String s in list){
     l.add(DropdownMenuItem(value:s,child:Text(s)));
   }
   return l;
 }

 List<Widget> history(){
   List<Widget> l=[];
   l.add(const Text('История / последние 5'));
   for(String s in hist){
    l.add(Padding(padding:const EdgeInsets.only(top:8),child:Text(s)));
   }
   return l;
 }

 @override
 Widget build(BuildContext context){
   return Scaffold(backgroundColor:const Color(0xffe9e4d8),
    appBar:AppBar(title:const Text('Конвертер валют'),
     backgroundColor:const Color(0xff39424e),foregroundColor:Colors.white),
     body:SafeArea(child:SingleChildScrollView(
      padding:const EdgeInsets.all(18),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
       const Text('Конвертатор курса',style:TextStyle(fontSize:12)),
       const SizedBox(height:18),
       TextField(controller:c,
         keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),
        textInputAction:TextInputAction.done,
         onChanged:(s){setState((){ok=false;err='';});},
        decoration:const InputDecoration(labelText:'Сумма',border:OutlineInputBorder()),
       ),
       const SizedBox(height:16),
       Row(children:[
        const Text('Из:  '),
         Expanded(child:DropdownButton<String>(value:a,isExpanded:true,
          items:items(),onChanged:(v){
           if(v==null)return;
           setState(() {a=v;ok=false;err='';});
         })),
       ]),
       Center(child:IconButton(onPressed:swap,
        icon:const Icon(Icons.swap_vert),tooltip:'Поменять валюты местами')),
       Row(children:[
         const Text('В:    '),
        Expanded(child:DropdownButton<String>(value:b,isExpanded:true,
         items:items(),onChanged:(v){
          if(v==null)return;
           setState((){b=v;ok=false;err='';});
        })),
       ]),
       const SizedBox(height:18),
       ElevatedButton(onPressed:load?null:calc,
        style:ElevatedButton.styleFrom(backgroundColor:Colors.green.shade700,foregroundColor:Colors.white),
         child:const Text('Конвертировать')),
       const SizedBox(height:16),
       if(load)const Center(child:CircularProgressIndicator()),
       if(err!='')Text(err,style:const TextStyle(color:Colors.red),textAlign:TextAlign.center),
       if(ok)Card(color:const Color(0xffa9b89a),
         child:Padding(padding:const EdgeInsets.all(16),
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
           const Text('Результат'),
           const SizedBox(height:10),
           Text(rez.toStringAsFixed(2)+' '+b,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
           const SizedBox(height:10),
           Text('1 '+a+' = '+k.v.toStringAsFixed(6)+' '+b),
           Text('Курс на '+k.d),
           Text('Обновлено: '+k.t+' (местное время)'),
          ]),
        )),
       const SizedBox(height:18),
       if(hist.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(16),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:history()))),
      ]),
    )),
   );
 }

 @override
 void dispose(){
  c.dispose();
   super.dispose();
 }
}

class Rate {
 double v;
 String d,t;
 Rate(this.v,this.d,this.t);
}

class Repo{
 Api api=Api();
 Future<Rate> get(String a,String b)async{
   Map<String,dynamic> j=await api.get();
   try{
     double x=1,y=1;
     if(a!='RUB'){
      var q=j['Valute'][a];
      double v=(q['Value'] as num).toDouble();
       double n=(q['Nominal'] as num).toDouble();
      x=v/n;
     }
     if(b!='RUB'){
       var q=j['Valute'][b];
      double v=(q['Value'] as num).toDouble();
      double n=(q['Nominal'] as num).toDouble();
      y=v/n;
     }
     double v=x/y;
      String d=j['Date'];
     String t=j['Timestamp'];
      t=DateTime.parse(t).toLocal().toString().split('.')[0];
     Rate k=Rate(v,d.substring(0,10),t);
     return k;
   }catch(e){throw Exception('Неверные данные курса');}
 }
}

class Api{
 Future<Map<String,dynamic>> get()async{
   http.Response r;
   try{
    r=await http.get(Uri.parse('https://www.cbr-xml-daily.ru/daily_json.js'))
        .timeout(const Duration(seconds:12));
   }on TimeoutException{
     throw Exception('Сервер не отвечает. Попробуйте позже');
   }on http.ClientException{
    throw Exception('Нет связи. Проверьте интернет');
   }
   if(r.statusCode!=200)throw Exception('Ошибка сервера: '+r.statusCode.toString());
   try{
     Map<String,dynamic> j=jsonDecode(utf8.decode(r.bodyBytes));
     return j;
   }catch(e){throw Exception('Некорректный ответ сервера');}
 }
}