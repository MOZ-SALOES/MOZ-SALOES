const CACHE_NAME='moz-saloes-shell-v9';
const OFFLINE_URL='./offline.html';
const CORE_FILES=['./','./index.html','./manifest.webmanifest','./favicon.svg',OFFLINE_URL];
self.addEventListener('install',event=>{
 event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(CORE_FILES)).then(()=>self.skipWaiting()));
});
self.addEventListener('activate',event=>{
 event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith('moz-saloes-shell-')&&key!==CACHE_NAME).map(key=>caches.delete(key)))).then(()=>self.clients.claim()));
});
self.addEventListener('message',event=>{if(event.data?.type==='SKIP_WAITING')self.skipWaiting();});
self.addEventListener('fetch',event=>{
 const request=event.request;if(request.method!=='GET')return;
 const url=new URL(request.url);if(url.origin!==self.location.origin)return;
 if(!url.pathname.startsWith(new URL('./',self.registration.scope).pathname))return;
 if(request.mode==='navigate'){
  event.respondWith(fetch(request,{cache:'no-store'}).then(response=>{
   if(response.ok){const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put('./index.html',copy));}
   return response;
  }).catch(async()=>{const cache=await caches.open(CACHE_NAME);return (await cache.match(request))||(await cache.match('./index.html'))||(await cache.match(OFFLINE_URL));}));
  return;
 }
 if(url.pathname.endsWith('.webmanifest')||url.pathname.endsWith('.svg')||url.pathname.endsWith('.png')||url.pathname.endsWith('.jpg')||url.pathname.endsWith('.webp')){
  event.respondWith(fetch(request,{cache:'no-store'}).then(response=>{
   if(response.ok){const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put(request,copy));}
   return response;
  }).catch(()=>caches.match(request)));
 }
});

self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=new URL(event.notification.data?.url||'./#owner',self.registration.scope).href;
 event.waitUntil((async()=>{
  const windows=await self.clients.matchAll({type:'window',includeUncontrolled:true});
  for(const client of windows){if('focus' in client){if('navigate' in client)await client.navigate(target);return client.focus();}}
  if(self.clients.openWindow)return self.clients.openWindow(target);
 })());
});
