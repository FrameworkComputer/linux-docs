```
sudo tee -a /usr/share/libinput/50-framework.quirks > /dev/null <<'EOF'
[Framework Laptop 16 Keyboard Module]
MatchName=Framework Laptop 16 Keyboard Module*
MatchUdevType=keyboard
MatchDMIModalias=dmi:*svnFramework:pnLaptop16*
AttrKeyboardIntegration=internal
EOF
```
