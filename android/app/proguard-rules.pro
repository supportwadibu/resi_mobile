# google_mlkit_text_recognition référence les reconnaisseurs chinois,
# devanagari, japonais et coréen, livrés comme dépendances optionnelles.
# Seul le script latin est embarqué (pièces d'identité ivoiriennes) : sans
# ces règles, R8 échoue sur des classes que l'application n'appelle jamais.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
