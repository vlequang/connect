//	HACK => always go in
if(true || window==top && !window.synco) {
    window.synco = true;
    var syncoHost = "https://my.adobeconnect.com";
    var syncoPath = "https://my.adobeconnect.com/connectsynco";
    var connectWindow, origin = syncoPath;
    var callbacks = [null];
    var recycleCallbacks = [];
    var chats = [];
    var chat, inputbox, msgbox, whiteboard;
    var pollInterval;
    var placeHolders = {};
    var imageHolder = {};
    
    var connectDiv = document.createElement('div');
    connectDiv.id = "connect";
//    connectDiv.style.position='absolute';
    connectDiv.style.zIndex = 10000;
    connectDiv.width = "320px";
    document.body.insertBefore(connectDiv,document.body.firstChild);

    function enterRoom(room) {
          connectWindow.postMessage({action:"enter",room:room},origin);
    }
    
    function exitRoom() {
          connectWindow.postMessage({action:'exit'},origin);
    }
    
    function refreshWorld() {
        for(var id in placeHolders) {
           var element = placeHolders[id];
           var containerID = id + 'container';
           var container = document.getElementById(containerID);
           if(container && element && element.parentElement!=container) {
           	  container.innerHTML = "";
              container.appendChild(element);
           }
        }
    }

    var tmpimages = [new Image(),new Image()];
    var pendingSrc = {};
    
    function showVideo(src) {
       processVideo('connectvideo',src);
    }
    
    function showScreenshare(src) {
       processVideo('connectscreenshare',src);
    }
    
    function processVideo(id,src) {
           var img = imageHolder[id];
           if(!img) {
              img = document.createElement("img");
              img.id = id;
//              img.style.width="320px";
//              img.style.height="240px";
//              element.insertBefore(img,element.firstChild);
              imageHolder[id] = img;
           }
           pendingSrc[img.id] = src;
           
           if(src!=img.src && !infospace.loading[img.id]) {
             infospace.loading[img.id] = true;
             var im = tmpimages.pop();
             im.id = img.id;
             im.onload = onImageLoad;
             im.src = src;
           }
        placeHolders[id] = img;
    }
    
    function onImageLoad() {
       delete infospace.loading[this.id];
       var oldImg = imageHolder[this.id];
       imageHolder[this.id] = this;
       placeHolders[this.id] = this;
       if(oldImg.parentElement) {
	       oldImg.parentElement.insertBefore(this,oldImg);
	       oldImg.parentElement.removeChild(oldImg);
	   }
       tmpimages.push(oldImg);
       if(pendingSrc[this.id]!=this.src) {
          processVideo(this.id,pendingSrc[this.id]);
       }
    }

    function clearHistory() {
        chats = [];
        updateMessages();
    }
    
    var zIndex = 1;
    function getContext(id) {
       var canvas = document.getElementById(id);
       if(!canvas) {
          canvas = document.createElement('canvas');
          canvas.id = id;
          canvas.style.zIndex = zIndex++;
          canvas.style.position="absolute";
          canvas.width = 800;
          canvas.height = 600;
          whiteboard.appendChild(canvas);
       }
       return canvas.getContext('2d');
    }
    
    function draw(shape) {
            console.debug(shape);
        var svgns = "http://www.w3.org/2000/svg";
        if(!whiteboard) {
           whiteboard = document.createElementNS(svgns,'svg');
           whiteboard.setAttribute('xmlns','http://www.w3.org/2000/svg');
           whiteboard.setAttribute('xmlns:xlink','http://www.w3.org/1999/xlink');
           whiteboard.setAttribute('version', '1.1');
           whiteboard.setAttribute('id', 'whiteboard');
           whiteboard.setAttribute('width',800);
           whiteboard.setAttribute('height',600);
           whiteboard.setAttributeNS (null, "viewBox", "0 0 " + 800 + " " + 600);
           whiteboard.style.display = 'block';
           placeHolders.whiteboard = whiteboard;
           
        }
        var wbShape = document.getElementById('shape'+shape.id);
        
        if(shape.delete) {
           if(wbShape) {
              whiteboard.removeChild(wbShape);
              return;
           }
        }
        
        if(!wbShape) {
            wbShape = document.createElementNS(svgns,'path');
            wbShape.id = 'shape'+shape.id;
            whiteboard.appendChild(wbShape);
        }
        
        if(shape.fillColor) {
            wbShape.setAttributeNS(null,'fill',shape.fillColor);
            wbShape.setAttributeNS(null,'fill-opacity',shape.alpha);
        }
        else {
            wbShape.setAttributeNS(null,'fill','none');
        }
        if(shape.strokeColor && shape.thickness) {
            wbShape.setAttributeNS(null,'stroke-width',shape.thickness);
            wbShape.setAttributeNS(null,'stroke',shape.strokeColor);
            wbShape.setAttributeNS(null,'stroke-opacity',shape.alpha);
        }
        var paths = [];
        for(var i=0;i<shape.path.length;i++) {
            paths[i] = shape.path[i].join(" ");
        }
        wbShape.setAttributeNS(null,'d',paths.join(" "));
    }
    
    function updateChat() {
        var html = "";
        for (var i=0;i<chats.length;i++) {
            var message = chats[i];
            html += "<b>"+message.fromName+"</b>: ";
            html += "<font color='"+message.color+"'>"+message.text+"</font>";
            html +=  "<br>\n";
        }
        var messages = html;
        
        if(!chat) {
           chat=document.createElement('div');
           chat.id='chat';
           chat.style.backgroundColor = '#EEFFFF';
           placeHolders.chat = chat;
        }
        if(!inputbox) {
           chat.insertBefore(inputbox=document.createElement('input'),chat.firstChild); 
           inputbox.type='text'; 
           inputbox.addEventListener('keydown',
                function(event){ 
                    var keyCode = ('which' in event) ? event.which : event.keyCode; 
                    if(keyCode==13) { 
                        connectWindow.postMessage({success:true,action:'chat',message:inputbox.value},origin);
                        inputbox.value='';
                    }; 
                    return; 
                },false);
        }
        if(!msgbox) {
            chat.insertBefore(msgbox=document.createElement('div'),chat.firstChild);
        }
        msgbox.innerHTML = messages;
    }

    var onMessage = function (e) {   
//            console.debug(">",e.data);
//            console.debug(">",JSON.stringify([e.data,e.origin,syncoHost]));
            if(syncoHost.indexOf(e.origin)==0) {
                if(e.data.timeout) {
                    clearTimeout(e.data.timeout);
                    delete e.data.timeout;
                }
                for(var i=0;i<e.data.messages.length;i++) {
                   var message = e.data.messages[i];
                   if(message.callbackResult) {
                       var func = callbacks[message.callbackResult];
                       delete callbacks[message.callbackResult];
                       recycleCallbacks.push(message.callbackResult);
                       func(message.data);
                   }
                   else {
                      switch(message.action) {
                        case 'salut':
                            iframe.style.visibility = 'hidden';
                            connectWindow.postMessage({data:'trust',callbackResult:message.callbackID},origin);
                            break;
                        case "updateVideo":
                            updateVideo(message.room);
                            break;
                        case "updateScreenShare":
//                            updateScreenShare(message.room);
                            break;
                        case "loginRequired":
                            if(typeof(onLoginRequired)!='undefined') {
                               onLoginRequired();
                            }
                            else {
                               alert('Please login to '+syncoHost+' and come back to this page.');
                            }
                            break;
                        case "roomEntered":
                            if(typeof(onEnterRoom)!='undefined')
                                onEnterRoom(message.room);
                            break;
                        case "whiteboard":
                            for(var i=0;i<message.shapes.length;i++) {
                                var shape = message.shapes[i];
                                draw(shape);
                            }
                            break;
                        case "clearHistory":
                            clearHistory();
                            break;
                        case "receiveMessages":
                            var messages = message.messages;
                            chats = chats.concat(messages);
                            updateChat();
                            break;
                        case "video":
                            showVideo(message.src);
                            break;
                        case "screenshare":
                            showScreenshare(message.src);
                            break;
                      }
                    }
                }
            }
        }

    if (!window.addEventListener) {
        window.attachEvent("message", onMessage);
    }
    else {
        window.addEventListener("message", onMessage, false);
    }

	//	this is the CONNECT icon in the top left corner
    var iframe=document.createElement('iframe');
    iframe.id = 'connectcore';
    iframe.style.width = "100px";
    iframe.style.height = "100px";
    iframe.style.zIndex = 10000;
    iframe.style.border = "none";
    iframe.style.position = "absolute";
    iframe.style.top = 0;
    iframe.style.visibility = 'hidden';
    document.body.appendChild(iframe);
    iframe.src=syncoPath;
    
    var infospace = {action:'hi',loading:{}};
    initInterval = setInterval(
        function() {
            connectWindow = iframe.contentWindow;
            iframe.contentWindow.postMessage(infospace,'*');
            refreshWorld();
        },40
    );
}