class_name SandboxSheet
extends RefCounted
## The sandbox purchase sheet shown by the mock billing backend: makes it
## obvious no real money moves, and lets testers decline to test failures.


static func make(product: Dictionary) -> PromptCard:
	var title := "Sandbox purchase"
	var text := "%s\n%s\n\nTest mode: no money is charged.\nPrice in the live store: %s" % [
		String(product.get("title", product.id)), String(product.get("desc", "")), Store.price_label(product)]
	var card := PromptCard.make(title, text, [
		{"id": "buy", "text": "Buy (test)  %s" % Store.price_label(product), "color": UI.ACCENT},
		{"id": "cancel", "text": "Cancel"}], null, UI.BLUE)
	card.closed.connect(func(choice): Store.confirm_sandbox(String(product.id), choice == "buy"))
	return card
