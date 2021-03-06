﻿/******************************
 * MICKA 5.001
 * 2015-07-07
 * javascript
 * Help Service Remote Sensing  
******************************/

MD_COLLAPSE = "collapse.gif";
MD_EXPAND   = "expand.gif";
MD_EXTENT_PRECISION = 1000;
var md_mapApp = getBbox;
var md_pageOffset = 0;
var messages = {};
var confirmLeave = false;
var initialExtent = [12.09, 48.55, 18.86, 51.06];

var micka = {
};

String.prototype.trim = function() { return this.replace(/^\s+|\s+$/, ''); };

var eventParser = {
	getEvent: function(e){
		if (!e) e = window.event;
		return e;
	},
		
	getEventTarget: function(e) {
		if (!this.getEvent(e).target) this.getEvent(e).target = this.getEvent(e).srcElement;
		return this.getEvent(e).target;
	},
	
	eraseEvent: function(e) {
		if (e) e.stopPropagation()
    else	window.event.cancelBubble = true;
	},
	
	stopEvent: function(e){
		if(e.preventDefault){
			e.preventDefault();
			e.stopPropagation();
		}
    else e.returnValue = false;
	}
}

function md_getSimilar(obj, str){
  var elementy = obj.childNodes;
  var elSim = new Array();
  var pm = "";
  for(var i=0;i<elementy.length;i++) if(elementy[i].id){
    var pom = elementy[i].id.split("_");
    if(pom[0]==str) elSim.push(elementy[i]);
  } 
  return elSim;
}

function md_pridej(obj){
  var dold = obj.parentNode;
  var dnew=dold.cloneNode(true);
  var dalsi = dold.nextSibling;
  if(dalsi==null) dold.parentNode.appendChild(dnew); 
  else dold.parentNode.insertBefore(dnew,dalsi);
  var pom = dold.id.split("_");
  var elementy = md_getSimilar(dold.parentNode, pom[0]);
  md_removeDuplicates(dnew);
  //for(var i=(parseInt(pom[1])+1);i<elementy.length;i++) md_setName(elementy[i], pom[0]+"_"+i+"_");
  for(var i=0;i<elementy.length;i++) md_setName(elementy[i], pom[0]+"_"+i+"_");

  // --- vycisteni ---
  var nody = flatNodes(dnew, "INPUT");
  for(var i=0;i<nody.length;i++) if(nody[i].type=="text") nody[i].value = "";

  nody = flatNodes(dnew, "SELECT");
  for(var i=0;i<nody.length;i++) nody[i].selectedIndex=0;

  nody = flatNodes(dnew, "TEXTAREA");
  for(var i=0;i<nody.length;i++) nody[i].value="";

  var d = getMyNodes(dnew, "DIV");
  if(d[0]) d[0].style.display='block';
  
  window.scrollBy(0,dold.clientHeight);
  return dnew;
}


function md_removeDuplicates(obj){
  if(obj.hasChildNodes()){
    var i=0;
    while(i<obj.childNodes.length){
      var smazano = 0;
      if(obj.childNodes[i].nodeName=="DIV"){
        if(obj.childNodes[i].id){
          var pom=obj.childNodes[i].id.split("_");
          var podobne = md_getSimilar(obj, pom[0]);
          if(podobne.length>1){
            smazano=1;
            for(var j=1;j<podobne.length;j++){ 
              obj.removeChild(podobne[j]); 
            }
          } 
        }
        if(smazano==0) md_removeDuplicates(obj.childNodes[i]);
      }
      i++; 
    }
  }
}

function md_setName(obj, id){
  var re = RegExp(obj.id, "g");
  var inputs = flatNodes(obj, "INPUT");
  for(var i=0;i<inputs.length;i++){
	  if (inputs[i].type=="radio"){ 
		  inputs[i].name = 'RB_'+id;
	  }
	  else inputs[i].name = inputs[i].name.replace(re,id);
  }
  var inputs = flatNodes(obj, "SELECT");
  for(var i=0;i<inputs.length;i++){
    inputs[i].name = inputs[i].name.replace(re,id);
  }
  var inputs = flatNodes(obj, "TEXTAREA");
  for(var i=0;i<inputs.length;i++){
    inputs[i].name = inputs[i].name.replace(re,id);
  }
  var inputs = flatNodes(obj, "A");
  for(var i=0;i<inputs.length;i++){
    inputs[i].href = inputs[i].href.replace(re,id);
  }
  obj.id = id;
}

function md_smaz(obj){
  if(!confirm(HS.i18n('Delete') + " ?")) return;
  var toDel = obj.parentNode;
  var cont = toDel.parentNode;
  var pom = toDel.id.split("_");
  var elementy = md_getSimilar(cont, pom[0]);
  if(elementy.length>1) cont.removeChild(toDel);
  var elementy = md_getSimilar(cont, pom[0]);
  for(var i=0;i<elementy.length;i++) md_setName(elementy[i], pom[0]+"_"+i+"_");
}

function md_menu(akce,recno,profil){
  if(!parent.frames.mdMenu) return false;
  if(typeof(recno)!="number")recno='';
  s = 'micka_menu.php?ak='+akce+'&recno='+recno+'&prof='+profil;
  if(parent.frames.mdMenu.location.href.indexOf(s)<0)
    parent.frames.mdMenu.location.href=s;
}

function md_unload(e){
  	if(document.getElementById("md_inpform") && confirmLeave){  
  		return messages.leave + ' ?';
  	}
}

function elementInViewport(el) {
    var rect = el.getBoundingClientRect()

    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight &&
        rect.right <= window.innerWidth 
        )
}

function checkMenu(){
  //var a = document.getElementsByTagName('a');
  //for(i=0;i<a.length;i++) a[i].onclick=md_unload;
}

function elm(name){
  if(document.getElementById) return document.getElementById(name);
  else if(document.all) return document.all[name];
  else return document.layers[name];
}


function md_scroll(el){
  if(typeof el == 'string'){
	  var el = document.getElementById(el) || document.getElementById(el.replace('ins', 'V'));
  }
  if(el){
	  var e = el;
	  var h = document.getElementById('headBox').offsetHeight;

	  while(e=e.parentNode){
		  if(e.tagName=='BODY') break;
		  if(e.style.display=='none'){
			  e.style.display='block';
		  }
	  }
	  el.scrollIntoView(true);
		if(el.getBoundingClientRect().y && el.getBoundingClientRect().y < h){
				window.scrollBy(0, -h-10);
		}
		else if(el.getBoundingClientRect().top < h){
				window.scrollBy(0, -h-10);
		}  
	  el.parentNode.style.background="#FFFFA0"; //TODO do stylu
	  setTimeout(function(){
		  el.parentNode.style.background="";
		  }, 1000);
  }
}

function md_expand(obj){
  var rf = flatNodes(obj.parentNode.parentNode,'INPUT');
  if(!rf.length) rf = [rf];
  for(var i=0;i<rf.length;i++){
   	if((rf[i].type=='radio')&&(obj.name=rf[i].name)){
   	  var d = rf[i].parentNode.childNodes;
   	  for(var j=0;j<d.length;j++){
   	    if(d[j].nodeName=='DIV'){
        	if(rf[i]==obj){ 
        	 	var toClose = d[j]; 
        	}
        	else if(d[j].style.display!='none') {
        	  var data = '';
   	   		  var inputs = flatNodes(d[j],'INPUT');
   	  	    for(var k=0; k<inputs.length; k++) if(inputs[k].type=='text') data += inputs[k].value;
   	  	    var selects = flatNodes(d[j],'SELECT');
   	  	    for(var k=0; k<selects.length; k++) data += selects[k].value;
   	  	    var texts = flatNodes(d[j],'TEXTAREA');
   	  	    for(var k=0; k<texts.length; k++) data += texts[k].value;
   	  	    if(data){
   	  	    	var c = window.confirm(HS.i18n('Delete') + " ?");
   	  	    	if(!c){ 
   	  	    		rf[i].click();
   	  	    		return false;
   	  	    	}	
    				  for(var k=0; k<inputs.length; k++) if(inputs[k].type=="text") inputs[k].value = "";
    				  for(var k=0; k<texts.length; k++)  texts[k].value = "";
    				  for(var k=0; k<selects.length; k++) selects[k].selectedIndex=0;  	    	
   	  	    }  	
        	  d[j].style.display='none';
        	}	
        }
      }	  
    }
  }
  toClose.style.display='block';
  return false;
}

function md_dexpand(obj){
  var id=obj.id.substr(2);
  var o = document.getElementById("PB"+id);
  var d = getMyNodes(obj.parentNode, "DIV");
  o = d[0];
  var src = obj.src.substring(0, obj.src.lastIndexOf("/")+1);
  if(o){
    if(o.style.display=='block'){
      o.style.display='none';
      obj.src = src+MD_EXPAND;
    }  
    else {
      o.style.display='block'; 
      obj.src = src+MD_COLLAPSE;
    }
  }
}


function clickMenu(block, target){
  var me = window;
  confirmLeave = false;
  if(parent && parent.frames.main){
  	var me = parent.frames.main;
  } 
  if(block=="cancel"){
	  me.location="?ak=storno";
	  return;
  }
  if(block==-19){ 
	  md_pageOffset = me.document.body.scrollTop;
  }	  
  else{ 
	  md_pageOffset = 0;
  }
  me.confirmLeave = false;
  if(block==-20) me.location = "?ak=mdview&ak1=cancel&recno="+me.document.forms['md_inpform'].recno.value;
  else {
	var form =me.document.forms['md_inpform'];
  	form.target = "";
  	if(typeof(target) != 'undefined'){
  		form.target = target;
  	}
  	form.nextblock.value=block;
  	// kontrola validity HTML5, pokud neni, ulozi se bez kontroly
  	if(block==-1){
  		if(!form.checkValidity || form.checkValidity()){
  			form.submit();
  		}
  		else {
  			for(f=0; f < form.elements.length; f++){
  				if(!form.elements[f].validity.valid){
  					md_scroll(form.elements[f]);
  					break;
  				}
  			}
  			//alert(HS.i18n('Please, fill mandatory elements'));
  		}
  	}
  	else form.submit();
  }
}

function clickLink(block, target){
	if(block==-1){
		scroll(0,0);
	}
	document.forms['md_inpform'].target='';
 	document.forms['md_inpform'].nextblock.value=block;
 	if(target){
 		document.forms['md_inpform'].target=target;
 	}	
 	document.forms['md_inpform'].submit();
}

function clickProfil(id_profil, id_block){
	confirmLeave = false;
	document.forms['md_inpform'].target='';
	if (id_profil > -1) {
		document.forms['md_inpform'].nextblock.value=document.forms['md_inpform'].block.value;
		document.forms['md_inpform'].nextprofil.value = id_profil;
	}
	if (id_block > -1) {
		document.forms['md_inpform'].nextblock.value = id_block;
		document.forms['md_inpform'].nextprofil.value = document.forms['md_inpform'].profil.value;
	}
	document.forms['md_inpform'].submit();
}

function selProfil(obj){
	confirmLeave = false;
	document.forms['md_inpform'].target='';
	document.forms['md_inpform'].nextblock.value=document.forms['md_inpform'].block.value;
	document.forms['md_inpform'].nextprofil.value=obj.value;
	document.forms['md_inpform'].submit();
}

function chVal(e){
  if(this.value=='') return true;
  if(this.className=='N'){
    if(isNaN(this.value)){
      alert('Bad number!');
      return false;
    }
    else return true;
  }
  else if(this.className=='D'){
    if(lang=='cze'){
      var r = /^(((0?[1-9]|[12][0-9]|3[01])\.)?((0?[1-9]|1[0-2])\.)?)((18|19|20|99)\d{2})$/
      var msg = 'Špatný formát data. Musí být RRRR nebo MM.RRRR nebo DD.MM.RRRR';      
    }  
    else //if(lang=='en')
    {
      var r = /^((18|19|20|99)\d{2})(-(0?[1-9]|1[0-2])(-(0?[1-9]|[12][0-9]|3[01]))?)?$/
      var msg = 'Bad date format: YYYY or YYYY-MM or YYYY-MM-DD allowed.';
    }
    if(r.exec(this.value)) return true;
    else{
      alert(msg);
      return false;
    }
  }

}

function chTextArea(e){
   if(this.value.length>2000){
	 alert('Maximum 2000 characters.');
	 this.value = this.value.substr(0, 2000);
	 return false;
   }
}

function start(){
	var inpForm = document.getElementById("md_inpform");
	if(inpForm){
		confirmLeave = true;
		window.onbeforeunload = md_unload;
	}	 
	var inputs = document.getElementsByTagName("input");
	if(inputs.length>0) for(i=0;i<inputs.length;i++){
		//inputs[i].onkeyup=chVal;
		inputs[i].onblur=chVal;
	}
	var ta = document.getElementsByTagName("textarea");
	if(ta.length>0) for(i=0;i<ta.length;i++){
		ta[i].onkeyup=chTextArea;
		ta[i].change=chTextArea;
	}
	/*if(inpForm){
		confirmLeave = true;
		window.onbeforeunload = stopEdit
	}	 */
	if(parent && parent.frames.mdMenu){ 
		window.scrollTo(0, parent.frames.mdMenu.md_pageOffset);
	}
	// rodicovsky element
	var parent = document.getElementById("50");
	if(parent && parent.value){
		document.getElementById("parent-text").innerHTML = "...";
		var ajax = new HTTPRequest;
		ajax.get("csw/index.php?format=json&query=identifier%3D"+parent.value, "", drawParent, false); 
	}
}

var drawParent = function(r){
	if(r.readyState == 4){
		eval("result="+r.responseText);
		if(result.records && result.records[0]){
			document.getElementById("parent-text").innerHTML = result.records[0].title;
		}
	}  
}

/*function stopEdit(e){
	if(confirmLeave) return 'You should stop editing before leaving !!!';  
}

function md_delrec(id){
  if(confirm(Hs.i18n('Delete record') + ' ?')) this.location=("?ak=delete&recno="+id);
}*/

/* editovani */
function getMyNodes(epom, nodename){
  var newList = new Array();
  for(var i=0; i<epom.childNodes.length; i++){
    if(epom.childNodes[i].nodeName==nodename) newList.push(epom.childNodes[i]);
  }
  return newList;
}

function flatNodes(epom, nodename, theClassName){
	var newList = new Array();
	if(epom.hasChildNodes()){
		for(var i=0; i<epom.childNodes.length; i++){
			if(epom.childNodes[i].nodeName==nodename){
				if(theClassName == undefined || epom.childNodes[i].className.indexOf(theClassName)>-1){
					newList.push(epom.childNodes[i]);
				}	
			}	
			else {
				var pom = flatNodes(epom.childNodes[i], nodename, theClassName);
				for(var j=0; j<pom.length; j++) newList.push(pom[j]);
			}
		}
	}
	return newList;
}

function md_dexpand1(obj){
  var divs = flatNodes(obj, "DIV"); 
  var imgs = getMyNodes(obj, "IMG");
  if(divs.length>0) divs[0].style.display='block';
  if(imgs.length>0) imgs[0].src = imgs[0].src.substring(0, imgs[0].src.lastIndexOf("/")+1)+ MD_COLLAPSE; 
}

function kontakt(obj,type){
  md_elem=obj.parentNode;
  md_partyType=type;
  dialogWindow = openDialog("kontakty", "?ak=md_contacts", ",width=500,height=500,scrollbars=yes");
  md_dexpand1(md_elem);
}

function kontakt1(id, osoba, org, org_en, fce, fce_en, phone, fax, ulice, mesto, admin, psc, zeme, email, url, adrId){
	var inputs = flatNodes(md_elem, "INPUT"); 
	var selects = flatNodes(md_elem, "SELECT");
	for(i=0;i<inputs.length;i++){
		var v = inputs[i];
		var num = v.id.substr(0,4);
		//angl. organizace navíc
		if(v.id=="3760eng"){
			 v.value = org_en;
		}
		else if(v.id=="3770eng"){
			 v.value = fce_en;
		}
		else if(v.id=="7001"){
	        v.value = id;
	    }
	    else switch(num){
			case '3750': v.value = osoba; break;
			case '3760': v.value = org; break;
			case '3770': v.value = fce; break;
			case '4080': v.value = phone; break;
			case '4090': v.value = fax; break;
			case '3810': v.value = ulice; break;
			case '3820': v.value = mesto; break;
			case '3830': v.value = admin; break;
			case '3840': v.value = psc; break;
			case '3850': v.value = zeme; break;
			case '3860': v.value = email; break;
			case '3970': v.value = url; break;
			case '3801': if(adrId) v.value = adrId; break;
		}
	}
	if(md_partyType!=null){
		for(i=0;i<selects.length;i++) if(selects[i].id=='3791'){
			selects[i].value = md_partyType; 
			break;
		}
	}
	if(dialogWindow!=null) dialogWindow.close();
}

function thes(obj){
  md_elem = obj.parentNode;
  md_dexpand1(md_elem);
  var dialogWindow = openDialog("kontakty", "", ",width=400,height=500,scrollbars=no"); 
  dialogWindow.focus();
  var services = 'true';
  if(document.forms[0].ftext) var path = 'false'; 
  else{ 
  	var path = 'true';
  	if(obj.parentNode.parentNode.id.indexOf('_4752_')>-1) services = 'true';
  }	
  if(!dialogWindow.processResult) dialogWindow.location="thesaurus.php?path="+path+"&services="+services+"&lang="+lang;
}

function fromThesaurus(data){
  if(!md_elem) return false;
  var last = -1;
  var vyplneno=0;
  var mainLang = langs.substring(0,3);
  var thesName = null; 
  if(data.version.indexOf(",")>0){
	  var version = data.version.split(",");
	  thesName = version[0]+','+version[1];
  }
  else {
	  var pos = data.version.lastIndexOf(" ");
	  var version = new Array();
	  version[0] = data.version.substring(0,pos);
	  version[1] = data.version.substring(++pos);
	  thesName = version[0]+','+version[1];
	  // hack kvuli odlisnostem mezi GEMET a INSPIRE - uz nebude potreba :(
	  if(data.version.substr(0,7)=="INSPIRE"){
		  version[0] = "GEMET - INSPIRE themes";
		  version[1] = "version 1.0";
	  }
  }
  //kontrola citace thesauru
  /*for(i=0;i<inputs.length;i++){
    //ve vyhl. formulari
    if(inputs[i].id=='ftext'){
      inputs[i].value = data.terms[lang];
  	  window.focus();
      return;
    }
    else{
    }
  }*/
	var currThesNode = null;
	var inputs = flatNodes(md_elem, "INPUT"); 
	var selects = flatNodes(md_elem, "SELECT"); 
  	for(i=0;i<inputs.length;i++){
	    if(inputs[i].id=='3600'+mainLang){
	    	if(inputs[i].value==''){
	    	  	var currThesNode = md_elem;
	    		break;
	    	}
	    }
	}
  	if(!currThesNode){
	  	var inp2 = flatNodes(md_elem.parentNode.parentNode, "INPUT");
	  	for(i=0;i<inp2.length;i++){
	  		if(inp2[i].id=='3600'+mainLang){
	  			if((inp2[i].value)==thesName){
	  				currThesNode = inp2[i].parentNode.parentNode.parentNode;
	  			}
	  		}
		}
  	}
	if(!currThesNode){
		if(!confirm(messages.thes)) return;
		var currThesNode = md_pridej(flatNodes(md_elem, "A")[1]);
	}
	var inputs = flatNodes(currThesNode, "INPUT"); 
	var selects = flatNodes(currThesNode, "SELECT"); 
	
  //vyplneni thesauru
  for(i=0;i<inputs.length;i++){
	  var ll = langs.split("|"); 
	  for(var j in ll){
		  if(inputs[i].id=='3600'+ll[j]) inputs[i].value=version[0]+','+version[1];
		  else if(inputs[i].id=='3940') inputs[i].value=version[version.length-1]; 
		  else if(inputs[i].id=='530'+ll[j]){
			  last = i;
			  if(inputs[i].value!="") vyplneno++;
		  }
	  } 
  } 
  // vyplneni kw
  if(vyplneno>0){
    var d = md_pridej(inputs[last]);
    inputs = flatNodes(d, "INPUT");
    if(!elementInViewport(d)){
    	d.scrollIntoView(false);
    }	
  } 
  // jsou-li termíny
  if(data.terms){
	  for(i=0;i<inputs.length;i++){
		  for(var l in data.terms) if(inputs[i].id=='530'+l){
			  inputs[i].value=data.terms[l];
		  }
	  }
  }
  //je-li uri
  if(data.uri) {
	  for(i=0;i<inputs.length;i++){
		  if(inputs[i].id=='530uri'){
			  inputs[i].value=data.uri; 
			  break;
		  } 
	  }
  }
  // tady přidání URI
  /*if(data.uri){
	    d = md_pridej(inputs[inputs.length-1]);
	    inputs = flatNodes(d, "INPUT");
	    if(!elementInViewport(d)){
	    	d.scrollIntoView(false);
	    }	
	    for(i=0;i<inputs.length;i++){
	        if(inputs[i].id.substring(0,3)=='530'){
	          inputs[i].value=data.uri;
	          break; // opsti po vyplneni prvi jazykove verze
	        }
	    }    
  }*/
  for(i=0;i<selects.length;i++){
    if(selects[i].id=='3950') selects[i].selectedIndex=2; // publication
  }
}

//verze2
function thes1(thesaurus, term_id, langs, terms, date, tdate){
  if(!md_elem) return false;
  var langs=langs.split(",");
  var terms=terms.split(",");
  var inputs = flatNodes(md_elem, "INPUT"); 
  var selects = flatNodes(md_elem, "SELECT"); 
  var last = -1;
  var vyplneno=0;
  for(i=0;i<inputs.length;i++){
    if(inputs[i].id=='ftext'){ // ve vyhled. formulari
      for(j=0;j<langs.length;j++){
        if(langs[j]==lang){
          inputs[i].value += terms[j]+" ";
          break;
        }
      } // mozno doplnit na anglictinu implicitne
      return;
    }  
    //zadavani
    else if(inputs[i].id=='3600') inputs[i].value=thesaurus; 
    else if(inputs[i].id=='3940') inputs[i].value=date; 
    else {
      //kontrola na prazdne hodnoty
      for(j=0;j<langs.length;j++) if(inputs[i].id=='530'+langs[j]){
        last = i;
        if(inputs[i].value!="") vyplneno++;
      }
    } 
  }
  if(vyplneno>0){
     var d = md_pridej(inputs[last]);
     inputs = flatNodes(d, "INPUT");
     if(!elementInViewport(d)){
     	d.scrollIntoView(false);
     }	
  }  
  for(i=0;i<inputs.length;i++)
    for(j=0;j<langs.length;j++) if(inputs[i].id=='530'+langs[j]){
      inputs[i].value=terms[j];
  }
  for(i=0;i<selects.length;i++){
    if(selects[i].id=='3951') selects[i].selectedIndex=tdate;
  }
}

function fc(obj){
  md_elem=obj.parentNode;
  dialogWindow = openDialog("kontakty", "?ak=md_fc", ",width=300,height=500,scrollbars=yes");
  md_dexpand1(md_elem);
}

function fc1(fcObj, lyrs){
  var lyrlist=lyrs.split(",");
  var inputs = flatNodes(md_elem, "INPUT"); 
  var selects = flatNodes(md_elem, "SELECT");
  var fList = new Array();
  //---vyplneni nazvu a uuid
  /*if(fcObj.langs.indexOf("|")>0){
    var langList = fcObj.langs.split("|");
    var nameList = fcObj.titles.split("|");
  }  
  else{
    var langList = [fcObj.langs];
    var nameList = [fcObj.titles];
  }*/  
  for(var i=0; i<inputs.length; i++){
    var v = inputs[i];
    if(v.id.substr(0,4)=='3600'){ 
    	v.value = '';
    	for(var lang in fcObj.titles){
    		if(lang && v.id==('3600'+lang)) v.value = fcObj.titles[lang];
    	}
    }   
    else switch(v.id){
      case '2370': fList.push(v); break;
      case '2070': v.value = fcObj.uuid;
      case '3940': if(fcObj.date[0]) v.value = fcObj.date[0][0];
    }
  }
  for(var i=0;i<selects.length;i++){
	    var v = selects[i];
  		if(v.id == '3950' && fcObj.date[0]) v.value = fcObj.date[0][1];	    
  }
  //---vyplneni vrstev
  for(i=1;i<fList.length;i++){ 
  	fList[i].parentNode.parentNode.removeChild(fList[i].parentNode);
  }	
  var f = fList[0];
  f.value=lyrlist[0];
  var inputs = getMyNodes(f.parentNode, "INPUT");
  for(var i=1;i<lyrlist.length;i++)if(lyrlist[i]!=""){
    var d = md_pridej(inputs[0]);
    inputs = getMyNodes(d, "INPUT"); 
    inputs[0].value=lyrlist[i]; 
  }
  if(dialogWindow!=null) dialogWindow.close();
}

function closeDialog(obj){
	if(obj) $(obj).parent().remove();
	else $('#md_dialog').remove();
}

function cover(obj){
	micka.window(obj, {
		title: 'Pokrytí území',
		name: 'cover-div',
		data: '<form onsubmit="return cover1()"><fieldset>'
			+'<label>Procenta:</label><input id="cover-perc" type="number" required="required" min="0" max="100" value="100"/>'
			+'<br/> <label>km2:</label><input type="number" id="cover-km" required="required" value="78866"/><br/>'
			+'<label>Popis:</label><input id="cover-desc" value="Pokrytí území ČR"><br/><label>Description:</label><input id="cover-desc-en" value="Coverage of CR territory"/><br/>'
			+'<input type="submit" value="OK"/></fieldset></form>'
	})
}

function cover1(){
	var divs = flatNodes(md_elem.parentNode, "DIV");
	var toClone = null;
	for(var i=0;i<divs.length;i++){
		if(divs[i].id=='2078_0_'){
			toClone = divs[i];
			md_dexpand1(divs[i]);
			var divs2 = flatNodes(flatNodes(divs[i], "DIV")[0],"DIV");
			md_dexpand1(divs2[0]);
		}	
		else if (divs[i].id=='2078_1_') toClone = null;
	}
	if(toClone){
		var a = flatNodes(toClone, "A");
		md_pridej(a[0]);
	}
	var inputs = flatNodes(md_elem.parentNode, "INPUT");
	for(var i=0;i<inputs.length;i++){
		if(inputs[i].id=='1000') inputs[i].value='Pokrytí';	
		else if(inputs[i].id=='2070') inputs[i].value='CZ-COVERAGE';
		else if(inputs[i].id=='1020cze') {
			inputs[i].value=$('#cover-desc').val();
		}	
		else if(inputs[i].id=='1020eng') {
			inputs[i].value=$('#cover-desc-en').val();
		}	
		else if(inputs[i].id=='30020' && inputs[i].name.indexOf('2078_0_2101')>0) inputs[i].value='http://geoportal.gov.cz/res/units.xml#percent';	
		else if(inputs[i].id=='1370' && inputs[i].name.indexOf('2078_0_2101')>0) inputs[i].value= $('#cover-perc').val();	
		else if(inputs[i].id=='30020' && inputs[i].name.indexOf('2078_1_2101')>0) inputs[i].value='http://geoportal.gov.cz/res/units.xml#km2';	
		else if(inputs[i].id=='1370' && inputs[i].name.indexOf('2078_1_2101')>0) inputs[i].value= $('#cover-km').val();	
	}
	$("#cover-div").remove();
	return false;
}

function find_parent(obj){
  md_elem = obj.parentNode;
  dialogWindow = openDialog("find", "?ak=md_search", ",width=500,height=500,scrollbars=yes");
  dialogWindow.focus();
}

function find_parent1(data){
	var code = md_elem.id.substring(0,4);
	switch(code){
	    // pro zavisle zdroje - pro sluzby (operatesOn)
		case '5120':
		case '1151':			
		    var inputs = flatNodes(md_elem, "INPUT");
		    for(var i=0;i<inputs.length;i++){
		        if(data.idCode){
		        	if(inputs[i].id.substr(0,4)=='3600'){ 
		        		if(data.idNameSpace.substr(0,4)=="http") inputs[i].value=data.idNameSpace+"#"+data.idCode;
		        		else inputs[i].value= data.idNameSpace+":"+data.idCode;
		        	} 
		        }
		      	if(inputs[i].id.substr(0,4)=='3600') inputs[i].value=data.title;
		      	else if(inputs[i].id.substr(0,4)=='3601') inputs[i].value=data.title;
		      	else if(inputs[i].id.substr(0,4)=='6001') inputs[i].value=data.uuid;
		      	else if(inputs[i].id.substr(0,4)=='3002'){
		      		var cid = (code=='1151') ? '#cit-' : '#_';
		      		inputs[i].value=location.href.replace(/\\/g, '/').replace(/\/[^\/]*\/?$/, '')
		      		+'/csw/index.php?SERVICE=CSW&VERSION=2.0.2&REQUEST=GetRecordById&OUTPUTSCHEMA=http://www.isotc211.org/2005/gmd&ID='+data.uuid+cid+data.uuid;
		      	}	
		    }
		    return false;
		    break;
		// pro zavisle zdroje - pro sluzby (coupledResource) - nebude pouzito
		case '5902':
		    var inputs = flatNodes(md_elem, "INPUT");
		    for(var i=0;i<inputs.length;i++){
		        /*if(data.idCode){
		        	if(inputs[i].id.substr(0,4)=='3583') inputs[i].value=data.idCode;
		        	else if(inputs[i].id.substr(0,4)=='3584') inputs[i].value=data.idNameSpace;
		        }*/
		      	if(inputs[i].id.substr(0,4)=='3600') inputs[i].value=data.title;
		      	else if(inputs[i].id.substr(0,4)=='3650') inputs[i].value=data.uuid;
		    }
		    return false;
		    break;
		default:	    
		  // pro ostatni
		  var inputs = flatNodes(md_elem, "INPUT");
		  for(var i=0;i<inputs.length;i++){
		    if(inputs[i].type=='text'){
		      inputs[i].value=data.uuid;
		      break;
		    }  
		  }
	}	  
	// pro importni formulare
	if(md_elem.id=='fill-rec') var txt = document.getElementById("fill-rec-txt");
	else if(md_elem.id=='fill-fc') var txt = document.getElementById("fill-fc-txt");
	// pro data
	else var txt = document.getElementById("parent-text");
	txt.innerHTML=data.title;
}

function find_fc(obj){
  md_elem = obj.parentNode;
  dialogWindow = openDialog("find", "?ak=md_search&fc=1", ",width=500,height=500,scrollbars=yes"); 
  dialogWindow.focus();
}

function find_fc1(uuid, name){
  inputs = flatNodes(md_elem, "INPUT");
  for(var i=0;i<inputs.length;i++){
    if(inputs[i].type=='text') inputs[i].value=uuid;
    break;
  }  
  var txt = document.getElementById("parent_text");
  txt.innerHTML=name;
}

function find_record(obj){
  md_elem = obj.parentNode;
  dialogWindow = openDialog("find", "?ak=md_search", ",width=500,height=500,scrollbars=yes"); 
  dialogWindow.focus();
}

function roundBbox(bbox){
  for(var i=0;i<bbox.length;i++){
    pom = bbox[i].split(" ");
    bbox[i] = Math.round(pom[0]*MD_EXTENT_PRECISION)/MD_EXTENT_PRECISION+" "+Math.round(pom[1]*MD_EXTENT_PRECISION)/MD_EXTENT_PRECISION;
  }
  return bbox;
}

function getBbox(bbox, isPoly){
  if(md_elem==null)return false;
  var poly = flatNodes(md_elem, "TEXTAREA");
  if(poly)  poly=poly[0];
  var inputs = flatNodes(md_elem, 'INPUT');
  for(var i=0;i<inputs.length;i++){
    switch(inputs[i].id){
      case '3440': var x1 = inputs[i]; break;
      case '3450': var x2 = inputs[i]; break;
      case '3460': var y1 = inputs[i]; break;
      case '3470': var y2 = inputs[i]; break;
    }
  }
  var bbox1=roundBbox(bbox.split(","));
  if(isPoly){ // polygon
  	if(!poly){
      alert('polygon not defined in profile');
      return;
    } 
    var s = "";
    for(var i=0;i<bbox1.length;i++) s += ',' + bbox1[i];     
    poly.value = "MULTIPOLYGON((("+s.substr(1)+","+bbox1[0]+")))";
    inputs = flatNodes(poly.parentNode.parentNode.parentNode, "INPUT");
    for(var i=0;i<inputs.length; i++){
      if(inputs[i].type=="radio"){
        inputs[i].click();
        break;
      }  
    }
    //vymazani BBOX
    x1.value = '';
    x2.value = '';
    y1.value = '';
    y2.value = '';
  }
  else { // jen BBOX
    var pom = bbox.replace(/,/g, ' ').split(' ');
    for(var i=0;i<pom.length;i++) pom[i] = Math.round(pom[i]*MD_EXTENT_PRECISION)/MD_EXTENT_PRECISION;
    x1.value=pom[0];
    y1.value=pom[1];
    x2.value=pom[2];
    y2.value=pom[3];
    var e = getMyNodes(md_elem, "DIV");
    var r = flatNodes(e[0], "INPUT");
    console.log(e, r);
    r[0].click();
    //vymazani polygonu
    if(poly){
       poly.value = '';
    }    
  }
}


function openDialog(okno, url, win){
  var win = window.open(url, okno, "toolbar=no,location=no,directories=no,status=yes,menubar=no,scrollbars=no,resizable=yes,copyhistory=no,"+win);
  win.focus();
  return win;
}

function mapa(obj){
	md_elem=obj.parentNode;
    var draw; // global so we can remove it later
    var features;
    var polygon = null;
	//md_mapApp = getBbox;
	//openDialog('micka_mapa','/mapserv/hsmap/hsmap.php?project=micka_map', 'width=360,height=270');
	//openDialog('micka_mapa','mickaMap.php', 'width=360,height=270');
	micka.window(obj,{
		title: obj.title,
		data: '<div id="overmap" style="width:330px; height:250px;"></div>'
			+ '<div>' + HS.i18n('Set extent') + ' [Ctrl] + ' + HS.i18n('draw') + '</div>'
			+ '<input type="checkbox" id="map-get-poly"> ' + HS.i18n('Draw polygon')
	});
	var input = flatNodes(md_elem,'INPUT', 'N');
	var ext = []; 
	// zpracovani polygonu
	var poly = flatNodes(md_elem,'TEXTAREA');
	if(poly.length>0 && poly[0].value != ""){
		var wkt = new ol.format.WKT();
		polygon = wkt.readFeature(poly[0].value, {dataProjection: 'EPSG:4326', featureProjection: 'EPSG:3857'});
		//ext = f.getGeometry().getExtent();
		//f.setId('r-1');
		//micka.flyr.getSource().addFeature(f);
	} 
	// zpracovani obdelniku
	else if(input[0].value){
		var y1 = parseFloat(input[2].value);
		var y2 = parseFloat(input[3].value);
		ext.push(parseFloat(input[0].value));
		ext.push(Math.max(-85,y1));
		ext.push(parseFloat(input[1].value));
		ext.push(Math.min(85,y2));
	}
	else {
		// asi docasu
		ext = initialExtent;
		input[0].value = ext[0];
  		input[2].value = ext[1];
  		input[1].value = ext[2];
  		input[3].value = ext[3];
	}
  	micka.initMap({
  		edit: true,
  		extent: ext,
  		polygon: polygon,
  		handler: function(bbox){
  			input[0].value = bbox[0].toFixed(3);
  			input[2].value = bbox[1].toFixed(3);
  			input[1].value = bbox[2].toFixed(3);
  			input[3].value = bbox[3].toFixed(3);
  		}
  	});
  	var polyCheck = document.getElementById('map-get-poly');
  	if(polyCheck) polyCheck.onclick = function(){
  		micka.mapfeatures.clear();
  		if(this.checked){
  			micka.overmap.getInteractions().forEach(function(el, i, a){
  				//console.log(el, i, a);
  				//console.log(el.getKeys());
  			}, micka.overmap)
  			//console.log(micka.overmap.getInteractions().items);
  			/*features = new ol.Collection();
  			var featureOverlay = new ol.layer.Vector({
  			  source: new ol.source.Vector({features: features}),
  			  style: new ol.style.Style({
  			    fill: new ol.style.Fill({
  			      color: 'rgba(255, 255, 255, 0.2)'
  			    }),
  			    stroke: new ol.style.Stroke({
  			      color: '#ffcc33',
  			      width: 2
  			    }),
  			    image: new ol.style.Circle({
  			      radius: 7,
  			      fill: new ol.style.Fill({
  			        color: '#ffcc33'
  			      })
  			    })
  			  })
  			});*/
  			//micka.overmap.addLayer(featureOverlay);
  			function addInteraction() {
	  			draw = new ol.interaction.Draw({
	  			    features: micka.mapfeatures,
	  			    type: 'Polygon'
	  			});
  			  	micka.overmap.addInteraction(draw);
  			  	draw.on('drawstart', function(){
  			  		micka.mapfeatures.clear();
  			  	})
  			  	draw.on('drawend', function(e){
  			  		var g = e.feature.getGeometry().clone();
  	  		        g.transform('EPSG:3857', 'EPSG:4326');
  	  		        var wkt = new ol.format.WKT();
  	  		    	var ta = flatNodes(md_elem,'TEXTAREA');
  	  		    	ta[0].value= wkt.writeGeometry(g);
  			  	})
  			}
  			addInteraction();

  		}
  		else {
  			draw.setActive(false);
  		}
  	}
}

function uploadFile(obj){
  md_elem = obj.parentNode.parentNode;
  openDialog('upload', 'md_img_upload.php', 'width=400,height=200');
}

function uploadFile1(fileURL){
  inputs = flatNodes(md_elem, "INPUT"); 
  for(var i=0;i<inputs.length;i++){
    if(inputs[i].id=='490'){ 
      inputs[i].value = fileURL; 
      break;
    }
  }
  window.focus();
}

function swapi(o){
  var pom=o.src.lastIndexOf(".");
  if(o.src.charAt(pom-1)=="_")o.src=o.src.substr(0,pom-1)+"."+o.src.substr(pom+1,10);
  else o.src=o.src.substr(0,pom)+"_."+o.src.substr(pom+1,10);
}

function formats(obj){
  md_elem = obj.parentNode;
  md_addMode = false;
  openDialog('formats', '?ak=md_lists&type=formats&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

function formats1(data){
	var inputs = flatNodes(md_elem, "TEXTAREA");
	if(inputs.length>0){
	    for(var i in inputs){
	      	if(typeof(data)=="object"){
	      		var lang = inputs[i].name.substr(1,3);
	      		var f = data[lang].value;
	      		if(!f) continue;
	      	}
	      	else f = data;
	      	if(md_addMode)inputs[i].value += f; 
	      	else inputs[i].value = f;
	    }   
	}
	else{
	  	var inputs = flatNodes(md_elem, "INPUT");
	    for(var i=0;i<inputs.length;i++){
	      	if(inputs[i].type=='text'){
	        	if(typeof(data)=="object"){
	      			var lang = inputs[i].id.substr(inputs[i].id.length-3);
	      			var f = data[lang].value;
	      			if(!f) continue;
	      		}
	      		else f = data;
	        	if(md_addMode)inputs[i].value += f; 
	        	else inputs[i].value = f;
	      	}   
	    }   
	}
}

function protocols(obj){
    md_elem = obj.parentNode;
    md_addMode = false;
    openDialog('protocol', '?ak=md_lists&type=protocol&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

function specif(obj){
    md_elem = obj.parentNode;
    md_addMode = false;
    openDialog('specif', '?ak=md_lists&type=specif&handler=specif1&multi=1&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

function specif1(f){
	var inputs = flatNodes(md_elem.parentNode.parentNode, "INPUT");
	for(var i=0;i<inputs.length;i++){
		v = inputs[i];
		for(var l in f){
			if(v.id=='3600'+l){
				v.value = f[l].name;
			}	
			if(v.id=='1310'+l){
				v.value = f[l].expl;
			}	
			else if(v.id=='3940') v.value = f[l].publication;
		}	
	}	
	var sels = flatNodes(md_elem.parentNode, "SELECT");
	for(var i=0;i<sels.length;i++){
		if(sels[i].id=='3950'){
			sels[i].value='publication';
		}
	}
	// pro kote
	var mainLang = document.forms[0].mdlang.value;
	var ta = flatNodes(md_elem.parentNode.parentNode, "TEXTAREA");
	for(var i in ta){
		if(ta[i].name.slice(-3)=='TXT') ta[i].value = f[mainLang].name;
		else ta[i].value =  f[ta[i].name.slice(-3)].name;
	}
	checkFields();
}

function hlname(obj){
    md_elem = obj.parentNode;
    md_addMode = false;
    openDialog('protocol', '?ak=md_lists&type=hlname&lang='+lang, 'width=400,height=500,scrollbars=yes');	
}



function fspec(obj){
	md_elem = obj.parentNode;
    openDialog('specif', '?ak=md_lists&type=fspec&multi=&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

function fspec1(f){
	var inputs = flatNodes(md_elem, "INPUT");
	inputs[0].value = f;
}

function crs(obj){
	md_elem = obj.parentNode;
	openDialog('crs', '?ak=md_lists&type=crs&handler=crs1&lang='+lang, 'width=200,height=400,scrollbars=yes');
}

function dName(obj){
    md_elem = obj.parentNode;
    md_addMode = false;
    openDialog('dname', '?ak=md_lists&type=dname&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

function crs1(f){
  var pom = f.split(",");
  var inputs = flatNodes(md_elem, "INPUT");
  for(var i=0;i<inputs.length;i++){
    v = inputs[i];
    switch(v.id){
      case '2070': v.value = pom[0]; break; 
      case '2081': v.value = pom[1]; break; 
    }     
  }
}

function dc_kontakt(obj){
  md_elem = obj.parentNode;
  dialogWindow = openDialog("kontakty", "ak=md_contacts&mds=DC", ",width=500,height=500");
}

function dc_kontakt1(osoba, org, fce, phone, fax, ulice, mesto, admin, psc, zeme, email, url){
  var inputs = flatNodes(md_elem, "INPUT");
  var s = osoba;
  if(s!="") s+= ", ";
  s += org;
  s += ", "+mesto;
  if(zeme.trim()!="") s+= ", "+zeme.trim();
  inputs[2].value = s;   
}

function dc_coverage(obj){
  md_elem = obj.parentNode;
  md_mapApp = dc_coverage1;
  openDialog('micka_mapa','mickaMap.php', 'width=360,height=270');
}

function dc_coverage1(s, b){
  var inputs = flatNodes(md_elem, 'INPUT');
  bbox = roundBbox(s.split(','));
  pom1 = bbox[0].split(' ');
  pom2 = bbox[1].split(' ');
  inputs[2].value = "westlimit:"+ pom1[0]+"; southlimit:"+pom1[1]+"; eastlimit:"+pom2[0]+"; northlimit:"+pom2[1];
}

function dc_subject(obj){
  md_elem = obj.parentNode;
  dialogWindow = openDialog("kontakty", "md_thes.php?standard=DC", ",width=300,height=500,scrollbars=yes"); 
}

function dc_subject1(thesaurus, term_id, langs, terms, date, tdate){
  if(!md_elem) return false;
  langs=langs.split(",");
  terms=terms.split(",");
  var inputs = flatNodes(md_elem, "INPUT"); 
  for(var i=0;i<inputs.length;i++){
    for(var j=0;j<langs.length;j++){
      if(inputs[i].id==('10003'+langs[j])){
        inputs[i].value=terms[j];
        break;
      }    
    } 
  }   
}

function dc_format(obj){
  md_elem = obj.parentNode;
  md_addMode = false;
  dialogWindow = openDialog("kontakty", "?ak=md_lists&standard=DC&type=formats&lang="+lang, ",width=400,height=500,scrollbars=yes"); 
}

function md_gazet(obj){
  md_elem = obj.parentNode.parentNode;
  dialogWindow = openDialog("kontakty", "?ak=md_gazcli", ",width=300,height=500,scrollbars=yes"); 
}

function md_gazet1(bbox, first){
  if(md_elem==null)return false;
  var poly = flatNodes(md_elem, "TEXTAREA");
  poly=poly[0];
  var inputs = flatNodes(md_elem, 'INPUT');
  for(var i=0;i<inputs.length;i++){
    switch(inputs[i].id){
      case '3440': var x1 = inputs[i]; break;
      case '3450': var x2 = inputs[i]; break;
      case '3460': var y1 = inputs[i]; break;
      case '3470': var y2 = inputs[i]; break;
    }
  }
  var bbox1=roundBbox(bbox.split(","));
  var s = "";
  if(first){ 
	  poly.value="";
	  inputs = flatNodes(poly.parentNode.parentNode.parentNode, "INPUT");
	  for(var i=0;i<inputs.length; i++){
	    if(inputs[i].type=="radio"){
	      inputs[i].click();
	      break;
	    }  
	  }
	  //vymazani BBOX
	  if(x1){
		  x1.value = '';
		  x2.value = '';
		  y1.value = '';
		  y2.value = '';
	  }
  }
  poly.value = poly.value.concat(bbox);

}

function importSelect(obj){
  var pom = document.getElementById('input_hide');
  if(obj.value.substr(0,4)=='ESRI') pom.style.display='';
  else pom.style.display='none';
  document.forms.newRecord.fc.value='';
  //document.getElementById('parent_text').innerHTML='';
}

function clearForm(){
  var fields = document.getElementsByTagName("INPUT");
  for(var i=0; i<fields.length;i++) if(fields[i].type=='text')fields[i].value='';
  var selects = document.getElementsByTagName("SELECT");
  for(i=0; i<selects.length;i++) selects[i].selectedIndex=0; 
  var texareas = document.getElementsByTagName("TEXTAREA");
  for(i=0; i<texareas.length;i++) texareas[i].value=''; 
  if(document.getElementById('results'))document.getElementById('results').innerHTML='';
  return false;
}

//vyplneni labelu v seznamu kontaktu
function fillLabel(o){
  if(o.value!="") return;
  var label=(document.forms[0].pers.value);
  var za = "";
  if (label!=""){
    var carka = label.lastIndexOf(",");
    if(carka>-1){za=label.substr(carka,99); label=label.substr(0,carka); }
    if(label.indexOf(" ")>-1){
      var jmena = label.split(" ");
      if(jmena.length>1){
        label = "";
        for(var i=jmena.length-1;i>=0;i--) label += jmena[i]+" ";
      }   
    }  
  }
  else label = document.forms[0].organisation.value;
  o.value=label+za;
}
 
function md_aform(obj,por,asnew){
  if(typeof(por) == 'undefined'){
    var pom = obj.parentNode.id.split('_');
    por = pom[1]; 
  }
  asnew = typeof(asnew) == 'undefined' ? 0 : asnew;
  var obsah = flatNodes(obj.parentNode, "DIV");
  if(obsah.length>0) var je = true;
  var el = document.getElementById('currentFeature');
  if(el){
    if(!window.confirm(messages.leave + ' ?')) return;
    var obrs = flatNodes(el.parentNode, "IMG");
    obrs[0].src = obrs[0].src.substring(0, obrs[0].src.lastIndexOf("/")+1) + MD_EXPAND; 
    el.parentNode.removeChild(el);
  } 
  if(je) return;  
  obj.src= obj.src.substring(0, obj.src.lastIndexOf("/")+1) + MD_COLLAPSE; 
  var container = document.createElement("div");
  container.id = 'currentFeature';
  obj.parentNode.appendChild(container);
  var url = "?ak=inmda&recno="+md_recno+"&por="+por+"&asnew="+asnew;
  var ajax = new HTTPRequest;
  ajax.get(url, "", md_drawFeature, false); 
}

function md_drawFeature(r){
  if(r.readyState == 4){
	  var el = document.getElementById('currentFeature');
	  if(el){
		  el.innerHTML = r.responseText+"<iframe name='featureFrame' style='display:none'></iframe>";
      //window.scrollTo(0, el.parentNode.offsetTop);
      //fc_initForm();
	  }
  }  
  else {
	  if(el) el.innerHTML = "<img src='themes/default/img/indicator.gif'>";
  }
}
  
function refreshFeature(por, label){
  var el = document.getElementById('currentFeature');
  if(!el){
    alert('Error: element not found!');
    return false;
  }  
  var spans = flatNodes(el.parentNode, "SPAN");
  spans[0].innerHTML = label;
  var obrs = flatNodes(el.parentNode, "IMG");
  obrs[0].src = obrs[0].src.substring(0, obrs[0].src.lastIndexOf("/")+1) + MD_EXPAND; 
  el.parentNode.id="12_"+por;
  el.parentNode.removeChild(el);
}


function fc_getId(obj){
  if(!obj) return -1; 
  var pom = obj.parentNode.id.split('_');
  return pom[1];
}

function fc_new(obj){
  var por = fc_getId(obj);
  //por = typeof(obj) == 'undefined' ? -1 : por;
  var newDiv = document.createElement("div");
  newDiv.id = "12_-1";
  newDiv.innerHTML="<img id=\"PA__0_\" onclick=\"md_aform(this);\" src=\"themes/default/img/expand.gif\"/><span class='f'>???</span><a href=\"javascript:void(0);\" onclick=\"fc_new(this);\"><img src='img/copy.gif'></a> <input class=\"b\" type=\"button\" onclick=\"fc_smaz(this);\" value=\"-\"/>";
  var obj = document.getElementById("addF");
  obj.parentNode.insertBefore(newDiv,obj);
  md_aform(newDiv.firstChild,por,1);
}

function fc_smaz(obj){
  if(!confirm(HS.i18n('Delete') + ' ?')) return false;
  var por = obj.parentNode.id.split('_');
  var url = "?ak=mddela&recno="+md_recno+"&por="+por[1];
  var ajax = new HTTPRequest;
  ajax.get(url, "", fc_smaz1, false); 
  obj.parentNode.parentNode.removeChild(obj.parentNode); //pak presunout do fc_smaz1
}

function fc_smaz1(r){
  if(r.readyState == 4) {}
}

function fc_storno(){
  var el = document.getElementById('currentFeature');
  if(el){
    var obrs = flatNodes(el.parentNode, "IMG");
    obrs[0].src = obrs[0].src.substring(0, obrs[0].src.lastIndexOf("/")+1) + "MD_EXPAND"; 
    var pom = el.parentNode.id.split('_');
    if(pom[1]==-1)el.parentNode.parentNode.removeChild(el.parentNode);
    else el.parentNode.removeChild(el);
  }
}

function showMap(url){
  // TODO - do konfigurace
  var myURL = "http://geoportal.gov.cz/web/guest/map?wms="+url;
  //var myURL = "http://onegeology-europe.brgm.fr/geoportal/viewer.jsp?id=" + url; 
  //window.open(myURL, "wmswin", "width=550,height=700,dependent=yes,toolbar=no,location=no,directories=no,status=yes,menubar=no,scrollbars=yes,resizable=yes,copyhist=no");
  var w = window.open(myURL, "portal", "");
  w.focus();
}

function md_datePicker(id){
  monthArrayLong = new Array('1 / ', '2 / ', '3 / ', '4 / ', '5 / ', '6 / ', '7 /', '8 / ', '9 / ', '10 / ', '11 / ', '12 / ');
  datePickerClose = " X ";
  if(lang=='cze'){
    dayArrayShort = new Array('Ne', 'Po', 'Út', 'St', 'Čt', 'Pá', 'So');
    datePickerToday = "Dnes";
  	displayDatePicker(id,false,'dmy','.');
  }	 
  else{
    displayDatePicker(id,false,'ymd','-');
  }  
}

var md_constraint = function(obj){
  md_elem = obj.parentNode;
  md_addMode = false;
  openDialog('protocol', '?ak=md_lists&type=uselim&multi=1&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

var md_serviceType = function(obj){
  md_elem = obj.parentNode;
  md_addMode = false;
  openDialog('protocol', '?ak=md_lists&type=service&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

var md_lineage = function(obj){
  md_elem = obj.parentNode;
  md_addMode = false;
  openDialog('protocol', '?ak=md_lists&type=lineage&multi=1&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

var md_processStep = function(obj){
  md_elem = obj.parentNode;
  md_addMode = true;
  openDialog('protocol', '?ak=md_lists&type=steps&multi=1&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

var oconstraint = function(obj){
  // md_elem = obj.parentNode;
  md_addMode = false;
  $.get('?ak=md_lists&type=oconstraint&multi=1&lang='+lang)
  	.done(function(data){
  		micka.window(obj,{
  			title: 'Omezení',
  			data: data
  		});
  	});
  //openDialog('protocol', '?ak=md_lists&type=oconstraint&multi=1&lang='+lang, 'width=400,height=500,scrollbars=yes');
}

micka.fillValues = function(listType, code){
	$.get("index.php?ak=md_lists&request=getValues&type="+listType+"&id="+code)
		.done(function(data){
			formats1(data);
			closeDialog();
		})
}

var changeSort = function(id, ordid, constraint, lang, recs){
	var o = document.getElementById(id);
	if(!o) return;
	var ord = document.getElementById(ordid);
	if(!ord) return;
	window.location="index.php?service=CSW&request=GetRecords&format=text/html&query="+ constraint + "&LANGUAGE=" + lang + "&MAXRECORDS=" + recs +"&sortby=" +o.value+":"+ord.value;
}

var showLogin = function(){
	var f = document.getElementById("loginForm");
	if(f){
		if(f.style.display=="inline-block"){
			f.style.display="none";
		}
		else{
			f.style.display="inline-block";
		} 	
	}

}

var checkId = function(o){
	var nody = flatNodes(o.parentNode.parentNode, "INPUT");
	if(nody[0].value!=''){
		ajax = new HTTPRequest;
		ajax.scope = o;		
		ajax.get("csw/?request=GetRecords&format=text/json&query=ResourceIdentifier%20like%20%27"+nody[0].value+"%27", null, checkIdBack, false);
	}
}

var checkIdBack = function(r){
	if(r.readyState == 4){
		var uuid = document.forms[0].uuid.value;
		eval("var data="+r.responseText);
		var dup = 0;
		if(data.matched == 0 || (data.matched == 1 && data.records[0].id == uuid)){
			ajax.scope.className="id-ok";
		}
		else {
			ajax.scope.className="id-fail";
			alert("ID již existuje");
		}
	}		  

}

var md_callBack = function(cb, uuid){
	if(cb.substring(0,6)=='opener'){
		var fn = cb.substring(7);
		ajax = new HTTPRequest;
		ajax.get("?ak=dummy&cb=", null, function(r){
			if(r.readyState == 4){
				if(!opener) {
					alert('Opener window is closed');
					return;
				}
				opener[fn](uuid);			
				window.close();
			}	
		}, false);
	}
}

var md_upload_run = function(o){
	var data = new FormData(o);
	$('#file-progress').css({display:'block'});
	$.ajax({ url: '?ak=md_upload', data: data, processData: false, contentType: false, type:"POST"})
	.done(function(result){
		var inp = flatNodes(md_elem.parentNode, 'INPUT');
		if(result) {
			inp[0].value = result;
			inp[1].value = 'WWW:DOWNLOAD-1.0-http--download';
			closeDialog();
		}
		else alert('Upload error');
	})
	return false;
}

var md_upload = function(obj, mime){
	micka.window(obj,{title:'Nahrát soubor', data:'<form name="fileUploadForm" onsubmit="return md_upload_run(this);"><input name="f" type="file"/><br><input type="submit" value="OK"/></form>'
	+ '<div id="file-progress" style="display:none">Nahrávám...</div>'
	});
}

micka.initMap=function(config){
	micka.extents = new Array();
	micka.mapfeatures = new ol.Collection();
	micka.flyr = new ol.layer.Vector({
		source: new ol.source.Vector({features: micka.mapfeatures}),
		style: new ol.style.Style({
			fill: new ol.style.Fill({
			    color: [0,0,0,0]
			}),
			stroke: new ol.style.Stroke({
			    color: '#3182BD',
			    width: 2
			}) 
	    })
	});

	micka.overmap = new ol.Map({
        target: "overmap",
        theme: null,
        layers: [
 			new ol.layer.Tile({	source: new ol.source.OSM() }),	                   
            micka.flyr
        ],
        view: new ol.View({
        	projection: 'EPSG:3857',
            center: [0,0], 
            zoom: 0
        })
    });
	
	// prochazi elementy
	var meta = document.getElementsByTagName("META");
	var ext = new Array();
	var tr = ol.proj.getTransform('EPSG:4326', 'EPSG:3857');
	
	// vezme z konfigu - ma prioritu
	if(config && config.polygon){
		ext = config.polygon.getGeometry().getExtent();
		config.polygon.setId('r-1');
		micka.flyr.getSource().addFeature(config.polygon);
	}
	else if(config && config.extent){
		ext = micka.addBBox(config.extent, "r-1");
	}
	else {
		for(var i=0; i<meta.length; i++){
			if(meta[i].getAttribute("itemprop")=="box"){
				var b = meta[i].getAttribute("content").split(" ");
				if(b && b.length==4){ 
					for (var j=0; j<b.length; j++){		
						b[j] = parseFloat(b[j]);
					}
					if(b[0]>=-180 && b[0]<=180){
						if(b[1]<-85) b[1] = -85;
						if(b[3]> 85) b[3] = 85;						
						ext = ol.extent.extend(micka.addBBox(b, "r-"+meta[i].getAttribute("id").split("-")[1]), ext);
					}
				}
			}
		}
	}

	// nastaveni rozsahu
	if(ext[0]){
		micka.overmap.getView().fit(ext, micka.overmap.getSize());
		micka.select = new ol.interaction.Select({
			multi: true,
			style: new ol.style.Style({
				fill: new ol.style.Fill({
				    color: [0,200,250,0.25]
				}),
				stroke: new ol.style.Stroke({
				    color: '#00E8FF',
				    width: 2
				}) 
		    })
		});
		micka.overmap.addInteraction(micka.select);
		micka.selFeatures = micka.select.getFeatures();
		micka.select.on('select', micka.hoverMap);
	}
	
	
	//-- pro LITE -- box
	if(config != undefined && config.edit == true){
		var dragBoxInteraction = new ol.interaction.DragBox({
	        condition: ol.events.condition.platformModifierKeyOnly,
	        code: 'AAA',
	        style: new ol.style.Style({
	          stroke: new ol.style.Stroke({
	            color: 'red',
	            width: 2
	          })
	        })
	    });
	
	    dragBoxInteraction.on('boxend', function(e) {
	        var g = e.target.getGeometry();
	        g.transform('EPSG:3857', 'EPSG:4326');
	        g = g.getExtent();
	        micka.mapfeatures.clear();
	        micka.addBBox(g, 'i-1');
	        if(config.handler){
	        	config.handler(g);
	        }
	        else { // TODO dat do samostatne fce - cfg ?
		        document.forms[0].xmin.value=g[0].toFixed(3);
		        document.forms[0].ymin.value=g[1].toFixed(3);
		        document.forms[0].xmax.value=g[2].toFixed(3);
		        document.forms[0].ymax.value=g[3].toFixed(3);
	        }
	    });
		micka.overmap.addInteraction(dragBoxInteraction);
	}
}

micka.addBBox = function(b, id){
	var g = new ol.geom.Polygon.fromExtent(b);
	g.transform('EPSG:4326', 'EPSG:3857');
	b = new ol.Feature({geometry: g	});
	b.setId(id);
	micka.flyr.getSource().addFeature(b);
	return g.getExtent();
}

micka.hover = function(o){
	if(!micka.flyr) return;
	var div;
	micka.selFeatures.forEach(function(e,i,a){
		div = document.getElementById(a[i].getId());
		if(div){
			div.style.background=""; // TODO - nejak jinak
		}					
	}, micka);
	micka.selFeatures.clear();
	micka.select.un('select', micka.hoverMap);
	var f = micka.flyr.getSource().getFeatureById(o.id);
	if(f){
		micka.selFeatures.push(f);
	}
}

micka.unhover = function(o){
	if(!micka.selFeatures) return;
	micka.selFeatures.clear();
	micka.select.on('select', micka.hoverMap);
}

micka.hoverMap = function(e) {
	var hdr = document.getElementById('headBox');
	var div;
	if(!micka.hoverColor){
		var css = document.styleSheets.item(1).cssRules; // TODO nejak dynamicky
		for(var i in css){
			if(css.item(i).selectorText=='div.rec:hover') {
				micka.hoverColor = css.item(i).style.backgroundColor;
				break;
			}
		}
	}
	for(i in e.deselected){
		div = document.getElementById(e.deselected[i].getId());
		if(div){
			div.style.background=""; // TODO - nejak jinak
		}			
	}
	for(i in e.selected){
		div = document.getElementById(e.selected[i].getId());
		div.style.backgroundColor = micka.hoverColor;
		if(i==0){
			div.scrollIntoView(true);
			window.scrollBy(0,-hdr.offsetHeight-3);
		}	
	}
}

micka.unhoverMap = function(e) {
	var div = document.getElementById(e.element.getId());
	if(div){
		div.style.background=""; // TODO - nejak jinak
	}	
}

micka.fromGaz = function(b){
	var g = b.split(" ");
    document.forms[0].xmin.value = Math.round(g[0]*1000)/1000;
    document.forms[0].ymin.value = Math.round(g[1]*1000)/1000;
    document.forms[0].xmax.value = Math.round(g[2]*1000)/1000;
    document.forms[0].ymax.value = Math.round(g[3]*1000)/1000;
    checkBBox();
}

micka.window = function(obj, par){
	md_elem = obj.parentNode;
	var wname = par.name || 'md_dialog';
	$("#"+ wname).remove();
	$("body").append('<div id="'+wname+'" class="md-dialog"><span class="close-dialog" onclick="closeDialog(this)"></span>'
		+'<h1>'+par.title+'</h1>'+par.data+'</div>');
}


