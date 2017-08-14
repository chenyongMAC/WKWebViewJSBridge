 (function() {
  if(window.RbJSBridge) {
		return;
  };
  
  var _callback_count = 1000,
		_callback_map = {},
		_event_hook_map = {},
		_CUSTOM_PROTOCOL_SCHEME = 'rubik',
		_MESSAGE_TYPE = '__msg_type',
		_CALLBACK_ID = '__callback_id',
		_EVENT_ID = '__event_id',
        _NEEDCALLBACK = 'needCallback',
		_QUEUE_SET_RESULT = 'private/setresult/';
  
  var _handleMessageIdentifier = _handleMessageFromApp;
  var _callIdentifier = _call;
  
  function _on(event, callback) {
		if(!event || typeof event !== 'string') {
  return;
		};
  
		if(typeof(callback) !== 'function') {
  return;
		};
  
		_event_hook_map[event] = callback;
  }
  
  // UTF8
  var UTF8 = {
  
  // public method for url encoding
  encode: function(string) {
  string = string.replace(/\r\n/g, "\n");
  var utftext = "";
  
  for (var n = 0; n < string.length; n++) {
  
  var c = string.charCodeAt(n);
  
  if (c < 128) {
  utftext += String.fromCharCode(c);
  } else if ((c > 127) && (c < 2048)) {
  utftext += String.fromCharCode((c >> 6) | 192);
  utftext += String.fromCharCode((c & 63) | 128);
  } else {
  utftext += String.fromCharCode((c >> 12) | 224);
  utftext += String.fromCharCode(((c >> 6) & 63) | 128);
  utftext += String.fromCharCode((c & 63) | 128);
  }
  
  }
  
  return utftext;
  },
  
  // public method for url decoding
  decode: function(utftext) {
  var string = "";
  var i = 0;
  var c = c1 = c2 = 0;
  
  while (i < utftext.length) {
  
  c = utftext.charCodeAt(i);
  
  if (c < 128) {
  string += String.fromCharCode(c);
  i++;
  } else if ((c > 191) && (c < 224)) {
  c2 = utftext.charCodeAt(i + 1);
  string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
  i += 2;
  } else {
  c2 = utftext.charCodeAt(i + 1);
  c3 = utftext.charCodeAt(i + 2);
  string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
  i += 3;
  }
  
  }
  
  return string;
  }
  
  };
  
  var base64encodechars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  
  function base64encode(str) {
		if(str === undefined) {
  return str;
		}
  
		var out, i, len;
		var c1, c2, c3;
		len = str.length;
		i = 0;
		out = "";
		while(i < len) {
  c1 = str.charCodeAt(i++) & 0xff;
  if(i == len) {
  out += base64encodechars.charAt(c1 >> 2);
  out += base64encodechars.charAt((c1 & 0x3) << 4);
  out += "==";
  break;
  }
  c2 = str.charCodeAt(i++);
  if(i == len) {
  out += base64encodechars.charAt(c1 >> 2);
  out += base64encodechars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4));
  out += base64encodechars.charAt((c2 & 0xf) << 2);
  out += "=";
  break;
  }
  c3 = str.charCodeAt(i++);
  out += base64encodechars.charAt(c1 >> 2);
  out += base64encodechars.charAt(((c1 & 0x3) << 4) | ((c2 & 0xf0) >> 4));
  out += base64encodechars.charAt(((c2 & 0xf) << 2) | ((c3 & 0xc0) >> 6));
  out += base64encodechars.charAt(c3 & 0x3f);
		}
		return out;
  }
  
  function _call(func, params, callback) {
		var curFuncIdentifier = RbJSBridge.call;
		if(curFuncIdentifier !== _callIdentifier) {
  return;
		}
		if(!func || typeof func !== 'string') {
  return;
		};
		if(typeof params !== 'object') {
  params = {};
		};

        var needCallBack = 0;
        var callbackID = (_callback_count++).toString();
		if(typeof callback === 'function') {
            needCallBack = 1;
            _callback_map[callbackID] = callback;
		};
  
        var msgObj = {
          'func': func,
          'params': params
        };
        msgObj[_MESSAGE_TYPE] = 'call';
        msgObj[_CALLBACK_ID] = callbackID;
        msgObj[_NEEDCALLBACK] = needCallBack;
		_sendMessage(JSON.stringify(msgObj));
  };
  
  function _sendMessage(message) {
  _setResultValue('_QUEUE_SET_RESULT', message)
  };
  
  
  function _setResultValue(scene, result) {
		if(result === undefined) {
  result = 'dummy';
		}
		_continueSetResult(scene + '&' + base64encode(UTF8.encode(result)));
  }
  
  function _continueSetResult(msg) {
  window.webkit.messageHandlers.RbJSBridgeEvent.postMessage(msg);
  }
  
  function _handleMessageFromApp(message) {
		var curFuncIdentifier = RbJSBridge._handleMessageFromApp;
		if(curFuncIdentifier !== _handleMessageIdentifier) {
  return '{}';
		}
		var ret;
		var msgWrap;
		msgWrap = JSON.parse(message);
  
		switch(msgWrap[_MESSAGE_TYPE]) {
  case 'callback':
  {
  if(typeof msgWrap[_CALLBACK_ID] === 'string' && typeof _callback_map[msgWrap[_CALLBACK_ID]] === 'function') {
  var ret = _callback_map[msgWrap[_CALLBACK_ID]](msgWrap['__params']);
  delete _callback_map[msgWrap[_CALLBACK_ID]]; // can only call once
  //window.JsApi && JsApi.keep_setReturnValue && window.JsApi.keep_setReturnValue('SCENE_HANDLEMSGFROMWX', JSON.stringify(ret));
  _setResultValue('SCENE_HANDLEMSGFROMWX', JSON.stringify(ret));
  return JSON.stringify(ret);
  }
  //window.JsApi && JsApi.keep_setReturnValue && window.JsApi.keep_setReturnValue('SCENE_HANDLEMSGFROMWX', JSON.stringify({'__err_code':'cb404'}));
  _setResultValue('SCENE_HANDLEMSGFROMWX', JSON.stringify({
                                                          '__err_code': 'cb404'
                                                          }));
  return JSON.stringify({
                        '__err_code': 'cb404'
                        });
  }
  break;
  case 'event':
  {
  if(typeof msgWrap[_EVENT_ID] === 'string') {
  if(typeof _event_hook_map[msgWrap[_EVENT_ID]] === 'function') {
  //window.JsApi && JsApi.keep_setReturnValue && window.JsApi.keep_setReturnValue('SCENE_HANDLEMSGFROMWX', JSON.stringify(ret));
  var ret = _event_hook_map[msgWrap[_EVENT_ID]](msgWrap['__params']);
  _setResultValue('SCENE_HANDLEMSGFROMWX', JSON.stringify(ret));
  return JSON.stringify(ret);
  }
  
  }
  //window.JsApi && JsApi.keep_setReturnValue && window.JsApi.keep_setReturnValue('SCENE_HANDLEMSGFROMWX', JSON.stringify({'__err_code':'ev404'}));
  _setResultValue('SCENE_HANDLEMSGFROMWX', JSON.stringify({
                                                          '__err_code': 'ev404'
                                                          }));
  return JSON.stringify({
                        '__err_code': 'ev404'
                        });
  }
  break;
		}
  };
  
  function _setDefaultEventHandlers() {
  // the first event
  _on('sys:init',function(ses){
      // 避免由于Java层多次发起init请求，造成网页端多次收到WeixinJSBridgeReady事件
      if (window.RbJSBridge._hasInit) {
      console.log('hasInit, no need to init again');
      return;
      }else{
      console.log('init RbJSBridge');
      }
      
      window.RbJSBridge._hasInit = true;
      
      // bridge ready
      var readyEvent = doc.createEvent('Events');
      readyEvent.initEvent('RbJSBridge');
      doc.dispatchEvent(readyEvent);
      });
  }
  
  var _RbJSBridge = {
		call: _call,
		_hasInit: false,
		_hasPreInit: false,
		_event_hook_map:_event_hook_map,
		on: _on,
  };
  
  try{
  Object.defineProperty(_RbJSBridge, '_handleMessageFromApp', {
                        value:_handleMessageFromApp,
                        writable:false,
                        configurable: false
                        });
  }catch(e){
  return
  }
  
  Object.defineProperty(window, 'RbJSBridge', {
                        value: _RbJSBridge,
                        writeable: false
                        });
  
  var doc = document;
  _setDefaultEventHandlers();
  })();
