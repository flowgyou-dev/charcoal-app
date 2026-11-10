import { initializeApp } from "firebase/app";
import { getDatabase } from "firebase/database";
import { getAuth } from "firebase/auth";

export const firebaseConfig = {
  apiKey: "AIzaSyBlfwSR2NBFTu4VkfbCs3hrj9H4bAw4Seg",
  authDomain: "charcoal-2fe4b.firebaseapp.com",
  databaseURL: "https://charcoal-2fe4b-default-rtdb.firebaseio.com",
  projectId: "charcoal-2fe4b",
  storageBucket: "charcoal-2fe4b.firebasestorage.app",
  messagingSenderId: "779328678183",
  appId: "1:779328678183:web:7c9582d3b6c817cfb16102"
};

const app = initializeApp(firebaseConfig);
export const db = getDatabase(app);
export const auth = getAuth(app);
export default app;
