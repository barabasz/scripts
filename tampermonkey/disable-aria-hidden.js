// ==UserScript==
// @name         Disable aria-hidden
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  remove all aria-hidden attributes from DOM
// @author       AB
// @match        *://*/*
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';
    document.querySelectorAll('[aria-hidden]').forEach(a=>a.removeAttribute('aria-hidden'));
})();
