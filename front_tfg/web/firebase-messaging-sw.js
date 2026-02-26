importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBTVsnTCHlHarF84pvcyiuAaVmDEyw609Y",
  authDomain: "proyectotfg-185c4.firebaseapp.com",
  projectId: "proyectotfg-185c4",
  storageBucket: "proyectotfg-185c4.firebasestorage.app",
  messagingSenderId: "1087451936722",
  appId: "1:1087451936722:web:8052655db3fcbcea0dba0b"
});

const messaging = firebase.messaging();