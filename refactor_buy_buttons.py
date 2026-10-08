import re

file_path = "lib/screens/economy/store_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Pattern for the style block:
# backgroundColor: _StoreColors.gold,
# -> backgroundColor: widget.item.currencyType == 'CRYSTALS' ? const Color(0xFFA855F7) : _StoreColors.gold,

content = re.sub(
    r"backgroundColor: _StoreColors\.gold,",
    r"backgroundColor: widget.item.currencyType == 'CRYSTALS' ? const Color(0xFFA855F7) : _StoreColors.gold,",
    content
)

# Pattern for the icon block:
# const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 14)
# -> Icon(widget.item.currencyType == 'CRYSTALS' ? Icons.diamond_rounded : Icons.monetization_on_rounded, color: Colors.white, size: 14)

content = re.sub(
    r"const Icon\(Icons\.monetization_on_rounded,\s*color: Colors\.white,\s*size: 14\)",
    r"Icon(widget.item.currencyType == 'CRYSTALS' ? Icons.diamond_rounded : Icons.monetization_on_rounded, color: Colors.white, size: 14)",
    content
)

# Pattern for ExtraCard where it says moedas:
# '${widget.item.price} moedas'
# -> '${widget.item.price} ${widget.item.currencyType == 'CRYSTALS' ? 'cristais' : 'moedas'}'
content = re.sub(
    r"'\$\{widget\.item\.price\} moedas'",
    r"'\${widget.item.price} \${widget.item.currencyType == \'CRYSTALS\' ? \'cristais\' : \'moedas\'}'",
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Done replacing.")
