import { BASE_PATH } from "@/lib/base-path";

/**
 * Owner 2026-11-24: while the website is being uploaded or changed, a bar at the top tells visitors that
 * new services are coming and that a short interruption may happen.
 *
 * The upload tool (builds/ftp_deploy.py) writes /site-status.json = {"updating": true} before it sends
 * any file and {"updating": false} when it ends. The file is not part of the build, so a missing file
 * means "no bar". This script is inline in every page (not in a Next chunk), so the bar still shows if a
 * page is half-updated and the app code fails to load. It checks again every minute and when the tab
 * comes back, so a page left open sees the bar appear and go away. Never throws.
 */
export const SITE_STATUS_SCRIPT = `(function(){try{
var B=${JSON.stringify(BASE_PATH)};
var AR="\\u062C\\u0627\\u0631\\u064D \\u062A\\u062D\\u062F\\u064A\\u062B \\u0627\\u0644\\u0645\\u0648\\u0642\\u0639 \\u0648\\u0625\\u0636\\u0627\\u0641\\u0629 \\u062E\\u062F\\u0645\\u0627\\u062A \\u062C\\u062F\\u064A\\u062F\\u0629. \\u0644\\u0648 \\u062D\\u0635\\u0644 \\u0623\\u064A \\u062A\\u0642\\u0637\\u064A\\u0639\\u060C \\u0627\\u0646\\u062A\\u0638\\u0631 \\u062F\\u0642\\u0627\\u0626\\u0642 \\u0648\\u062D\\u062F\\u0651\\u062B \\u0627\\u0644\\u0635\\u0641\\u062D\\u0629.";
var EN="The website is being updated with new services. If anything stops working, wait a few minutes and reload the page.";
function show(s){var el=document.getElementById('site-status');if(!el)return;
if(s&&s.updating===true){var ar=(document.documentElement.lang||'ar')!=='en';
var m=(ar?s.ar:s.en);el.textContent=(typeof m==='string'&&m)?m:(ar?AR:EN);el.hidden=false;}
else{el.hidden=true;}}
function check(){if(!window.fetch)return;fetch(B+'/site-status.json?t='+Date.now(),{cache:'no-store'})
.then(function(r){return r.ok?r.json():null}).then(show,function(){show(null)}).catch(function(){})}
if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',check)}else{check()}
setInterval(check,60000);
document.addEventListener('visibilitychange',function(){if(document.visibilityState==='visible')check()});
}catch(e){}})();`;
