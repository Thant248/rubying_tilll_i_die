import { useEffect, useRef, useState } from 'react'
import axios  from 'axios';
import './App.css'


const  ws = new WebSocket("ws://localhost:3000/cable");

function App() {
  const [messages, setMessages] = useState([]);
  const [guid, setGuid] = useState("");
  const messagesContainer = useRef(null);


  ws.onopen = () => {
    console.log("Connected to wescket server");
    setGuid(Math.random().toString(36).substring(2, 15))

    ws.send(
      JSON.stringify({
        command:  "subscribe",
        identifier: JSON.stringify({
            id: guid,
            channel: "MessagesChannel"
        }),
      })
    )
  }

  ws.onmessage = (e) => {
    const data = JSON.parse(e.data);
    if (data.type === "ping" || data.type === "welcome" || data.type === "confirm_subscription") return;

    const message = data.message;
    if (message) {
      setMessagesAndScrollDown([...messages, message]);
    } else {
      console.error("Received message is undefined or has no body:", data);
    }
  };

  useEffect(() => {
    fetchMessages();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    const body = e.target.message.value;
    e.target.message.value = "";
    const message = { body };
    await axios.post("http://localhost:3000/messages", { message }).then(res => {
      console.log(res);
      console.log(res.data);
    });
  }

  const fetchMessages = async () => {
    await axios.get("http://localhost:3000/messages").then(res => {
      const data = res.data;
      console.log(data);
      setMessagesAndScrollDown(data);
    });
  };

  const setMessagesAndScrollDown = (data) => {
    setMessages(data);
    if (!messagesContainer) return;
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  return (
    <>
      <div className='App'>
        <div className="messageHeader">
          <h1>Messages</h1>
          <p>Guid: {guid} </p>
        </div>
        <div className="messages" ref={messagesContainer} id='messages'>
          {messages.map((msg) => (
            <div className="message" key={msg.id}>
              <p>{msg.body}</p>
            </div>
          ))}
        </div>
        <div className="messageForm">
          <form onSubmit={handleSubmit}>
            <input className='messageInput' type="text" name='message' />
            <button className='messageButton' type='submit'>Send</button>
          </form>
        </div>
      </div>
    </>
  )
}

export default App
