import time
import subprocess

# ================= НАСТРОЙКИ =================
TREASURY = ""   
RPC = "https://bsc-dataseed.binance.org"
PRIVATE_KEY = ""    
# ============================================

def submit_vote(choice: int):
    """0 = Save, 1 = Strengthen, 2 = Punish"""
    subprocess.run([
        "cast", "send", TREASURY,
        "submitVote(uint8)", str(choice),
        "--private-key", PRIVATE_KEY,
        "--rpc-url", RPC
    ], check=True)

def register():
    subprocess.run(["cast", "send", TREASURY, "registerAgent()", "--private-key", PRIVATE_KEY, "--rpc-url", RPC])

if __name__ == "__main__":
    print("DARWIN Agent launched...")
    # register()
    
    while True:
       #Tobemade
        
        try:
            submit_vote(choice)
            print(f"Voted: {choice} | {time.strftime('%H:%M:%S')}")
        except Exception as e:
            print("Error:", e)
        
        time.sleep(900) 
