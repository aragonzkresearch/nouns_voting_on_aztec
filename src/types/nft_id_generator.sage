from sage.all import *

# Define the BN254 curve parameters
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
F = GF(p)

# Create the NFT_ID_LIST with random numbers modulo p
NFT_ID_LIST = [[F.random_element(), F.random_element()] for i in [0..256]]

# Print the NFT_ID_LIST
print("global NFT_ID_LIST: [[Field; 2]; 256] = [")
for i in range(0,256):
    nft_id_0 = "0x" + hex(NFT_ID_LIST[i][0]).replace('0x','').zfill(64)
    nft_id_1 = "0x" + hex(NFT_ID_LIST[i][1]).replace('0x','').zfill(64)
    print("[" + nft_id_0 +", " + nft_id_1 + " ],")
print("]")
