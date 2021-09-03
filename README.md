# HFR Rehost iOS Share Extension

Ceci est une extension iOS pour pouvoir partager une image depuis sa bibliothèque vers [Rehost](https://rehost.diberie.com/).

## Pourquoi

L'application n'est pas sur le store car je n'ai pas de compte développeur payant, et surtout j'ai la flemme. Elle a été crée en une soirée afin de me permettre d'utiliser plus efficacement le service depuis mon iPhone.

Elle n'est pas non plus intégrée dans l'application iOS HFR+, je ne connais pas le développeur principal, je ne sais pas si ça l'intéresse, mais si c'est le cas, redirigez le ici, on parle de même pas 300 lignes de code, il/elle saura sûrement le faire soi même.

## Comment builder

Il vous faudra XCode pour pouvoir builder le projet et l'installer sur vote téléphone.

Si vous avez ça, il vous suffit d'importer le projet XCode, puis de mettre vos credentials dans le fichier `ShareViewController.swift` à la ligne `104`:

```swift
// Update with your credentials
let params = ["Email" : "foo@bar.com", "Password": "abc123"]  // <---- ici
let postString = self.getPostString(params: params)
request.httpBody = postString.data(using: .utf8)
```

Une fois que c'est fait, buildez le projet et deploy sur votre iPhone.

## Comment l'utiliser

1. Ouvrez votre bibliothèque et choisissez la photo à partager
2. Cliquez sur "Share" puis sur "Rehost" avec le red face
3. L'extension se connecte et récupère vos Galleries, choisissez en une
4. Une fois terminé le BBCode à partager sur le forum se trouve dans votre presse papier
5. Collez le là où vous vouliez l'utiliser

Une image valant mieux que milles listes à puce:

![Scenario](https://rehost.diberie.com/Picture/Get/f/34741)