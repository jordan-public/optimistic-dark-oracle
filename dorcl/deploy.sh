
WALLETADDRESS="aleo1ec6mwdzfyydg9rsrqdpf3yrt46js4h7y8pyt4cwugfue728jc5qs5w5jp9"
PRIVATEKEY="APrivateKey1zkpCbsjb3m8BVkJ2YKRded1U2jGMaMzHA15zq9UT4gKV7jF"

APPNAME="dorcl"
PATHTOAPP=$(realpath -q $APPNAME)

RECORD="{
  owner: aleo1ec6mwdzfyydg9rsrqdpf3yrt46js4h7y8pyt4cwugfue728jc5qs5w5jp9.private,
  microcredits: 21331000u64.private,
  _nonce: 7730112076631917330407902914700545230553795158080686619595260826864067182149group.public
}"

cd .. && snarkos developer deploy "${APPNAME}.aleo" --private-key "${PRIVATEKEY}" --query "https://vm.aleo.org/api" --path "./${APPNAME}/build/" --broadcast "https://vm.aleo.org/api/testnet3/transaction/broadcast" --fee 1000000 --record "${RECORD}"``
