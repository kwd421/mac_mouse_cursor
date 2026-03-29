import Foundation

struct ResolvedTheme {
    let filesByRole: [CursorRole: URL]
    let fallbackRoles: Set<CursorRole>
}

struct ThemeResolver {
    static func displayKeywords(for role: CursorRole, language: AppLanguage = Localized.currentLanguage) -> String {
        let englishKeywords = displayKeywords[.english]?[role, default: []] ?? []

        if language == .english {
            return englishKeywords.joined(separator: ", ")
        }

        let localizedKeywords = displayKeywords[language]?[role, default: []] ?? []

        var seen = Set<String>()
        var ordered: [String] = []

        for keyword in englishKeywords + localizedKeywords {
            let normalized = normalizedKeyword(keyword)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { continue }
            ordered.append(keyword)
        }

        if !ordered.isEmpty {
            return ordered.joined(separator: ", ")
        }

        return orderedKeywords(for: role).joined(separator: ", ")
    }

    func resolveTheme(in directory: URL) throws -> ResolvedTheme {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw CursorError.missingTheme(directory.path)
        }

        let candidates = try directCursorFiles(in: directory)
        guard !candidates.isEmpty else {
            throw CursorError.invalidThemeSelection(Localized.string("error.invalidThemeSelection.noCursorFiles"))
        }

        var mapping: [CursorRole: URL] = [:]
        var fallbackRoles = Set<CursorRole>()

        for role in CursorRole.allCases {
            if let exact = candidates.first(where: { canonicalFileName($0.lastPathComponent) == canonicalFileName(role.themeFileName) }) {
                mapping[role] = exact
                continue
            }

            if let exactAlias = candidates.first(where: { Self.aliasStems(for: role).contains(canonicalStem($0)) }) {
                mapping[role] = exactAlias
                continue
            }

            let fuzzyMatches = candidates
                .map { ($0, fuzzyScore(for: role, candidate: $0)) }
                .filter { $0.1 > 0 }
                .sorted {
                    if $0.1 == $1.1 {
                        return canonicalStem($0.0) < canonicalStem($1.0)
                    }
                    return $0.1 > $1.1
                }

            if let best = fuzzyMatches.first?.0 {
                mapping[role] = best
            }
        }

        if mapping[.arrow] == nil, let fallback = fallbackArrowCandidate(from: candidates, excluding: Set(mapping.values.map(\.standardizedFileURL))) {
            mapping[.arrow] = fallback
        }

        if mapping[.busy] == nil, let working = mapping[.working] {
            mapping[.busy] = working
            fallbackRoles.insert(.busy)
        }

        if mapping[.working] == nil, let busy = mapping[.busy] {
            mapping[.working] = busy
            fallbackRoles.insert(.working)
        }

        if let arrow = mapping[.arrow] {
            for role in CursorRole.allCases where mapping[role] == nil {
                mapping[role] = arrow
                if role != .arrow {
                    fallbackRoles.insert(role)
                }
            }
        }

        return ResolvedTheme(filesByRole: mapping, fallbackRoles: fallbackRoles)
    }

    private func directCursorFiles(in directory: URL) throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter {
            ["ani", "cur"].contains($0.pathExtension.lowercased())
        }
    }

    private func fuzzyScore(for role: CursorRole, candidate: URL) -> Int {
        let name = canonicalStem(candidate)
        return Self.fuzzyKeywords[role, default: []].reduce(into: 0) { score, keyword in
            if name.contains(Self.normalizedKeyword(keyword)) {
                score += 1
            }
        }
    }

    private static let exactAliases: [CursorRole: [String]] = [
        .arrow: ["일반선택", "일반", "기본선택", "arrow", "normal", "pointer", "default"],
        .text: ["텍스트선택", "텍스트", "text", "ibeam"],
        .location: ["연결위치사용자선택", "위치선택", "location", "loc", "pin", "copy"],
        .link: ["연결위치사용자선택", "연결", "사용자선택", "링크", "link", "pointinghand"],
        .precision: ["정밀도선택", "정밀도", "precision", "crosshair", "cross"],
        .move: ["이동", "드래그", "move", "drag", "grab", "grabbing", "openhand", "closedhand", "移動", "ドラッグ", "移动", "移動中", "bewegen", "ziehen", "deplacer", "glisser", "mover", "arrastrar", "mover", "arrastar", "sposta", "trascina", "перемещение", "перетащить"],
        .unavailable: ["사용할수없음", "사용불가", "금지", "불가", "notallowed", "unavailable", "forbidden", "blocked", "noaccess", "使用不可", "禁止", "不可用", "不允許", "verboten", "nichtverfugbar", "indisponible", "interdit", "nodisponible", "prohibido", "indisponivel", "proibido", "nondisponibile", "vietato", "недоступно", "запрещено"],
        .busy: ["백그라운드작업사용중", "busy", "사용중"],
        .working: ["백그라운드작업사용중", "백그라운드작업", "백그라운드", "대기", "대기중", "작업중", "로딩", "working", "wait", "loading", "background", "待機", "作業中", "読み込み", "等待", "加载", "載入", "hintergrund", "warten", "laden", "attente", "chargement", "arriereplan", "espera", "cargando", "segundoplano", "carregando", "attesa", "caricamento", "sfondo", "ожидание", "загрузка", "фон"],
        .help: ["help", "도움말", "도움", "물음표", "question", "questionmark", "ヘルプ", "質問", "疑問符", "帮助", "幫助", "问号", "問號", "hilfe", "frage", "aide", "question", "ayuda", "ajuda", "aiuto", "помощь", "вопрос"],
        .handwriting: ["handwriting", "손글씨", "필기", "펜", "연필", "쓰기", "pen", "pencil", "write", "ink", "手書き", "ペン", "鉛筆", "手写", "筆", "笔", "書寫", "handschrift", "stift", "bleistift", "manuscrit", "stylo", "crayon", "escritura", "pluma", "lapiz", "caneta", "matita", "рукописный", "ручка", "карандаш"],
        .person: ["person", "cell", "사람선택"],
        .alternate: ["alternate", "alias", "별칭", "바로가기"],
        .verticalResize: ["수직크기조절", "vertical", "updown", "vert"],
        .horizontalResize: ["수평크기조절", "horizontal", "leftright", "horz"],
        .diagonalResizeNWSE: ["대각선방향크기조절1", "대각선1", "nwse", "diagonal1", "dgn1"],
        .diagonalResizeNESW: ["대각선방향크기조절2", "대각선2", "nesw", "diagonal2", "dgn2"]
    ]

    private static let fuzzyKeywords: [CursorRole: [String]] = [
        .arrow: ["일반선택", "일반", "기본선택", "arrow", "normal", "pointer", "default"],
        .text: ["텍스트선택", "텍스트", "text", "ibeam"],
        .location: ["연결위치사용자선택", "위치선택", "location", "loc", "pin", "copy"],
        .link: ["연결", "사용자선택", "링크", "link", "pointinghand"],
        .precision: ["정밀도선택", "정밀도", "precision", "crosshair", "cross"],
        .move: ["이동", "드래그", "move", "drag", "grab", "grabbing", "openhand", "closedhand", "移動", "ドラッグ", "移动", "移動中", "bewegen", "ziehen", "deplacer", "glisser", "mover", "arrastrar", "arrastar", "sposta", "trascina", "перемещение", "перетащить"],
        .unavailable: ["사용할수없음", "사용불가", "금지", "불가", "notallowed", "unavailable", "forbidden", "blocked", "noaccess", "使用不可", "禁止", "不可用", "不允許", "verboten", "nichtverfugbar", "indisponible", "interdit", "nodisponible", "prohibido", "indisponivel", "proibido", "nondisponibile", "vietato", "недоступно", "запрещено"],
        .busy: ["백그라운드작업", "사용중", "busy"],
        .working: ["백그라운드작업", "백그라운드", "대기", "대기중", "작업중", "로딩", "working", "wait", "loading", "background", "待機", "作業中", "読み込み", "等待", "加载", "載入", "hintergrund", "warten", "laden", "attente", "chargement", "arriereplan", "espera", "cargando", "segundoplano", "carregando", "attesa", "caricamento", "sfondo", "ожидание", "загрузка", "фон"],
        .help: ["help", "도움말", "도움", "물음표", "question", "questionmark", "ヘルプ", "質問", "疑問符", "帮助", "幫助", "问号", "問號", "hilfe", "frage", "aide", "ayuda", "ajuda", "aiuto", "помощь", "вопрос"],
        .handwriting: ["handwriting", "손글씨", "필기", "펜", "연필", "쓰기", "pen", "pencil", "write", "ink", "手書き", "ペン", "鉛筆", "手写", "筆", "笔", "書寫", "handschrift", "stift", "bleistift", "manuscrit", "stylo", "crayon", "escritura", "pluma", "lapiz", "caneta", "matita", "рукописный", "ручка", "карандаш"],
        .person: ["person", "cell", "사람선택"],
        .alternate: ["alternate", "alias", "별칭", "바로가기"],
        .verticalResize: ["수직크기조절", "vertical", "updown", "vert"],
        .horizontalResize: ["수평크기조절", "horizontal", "leftright", "horz"],
        .diagonalResizeNWSE: ["대각선방향크기조절1", "대각선1", "nwse", "diagonal1", "dgn1"],
        .diagonalResizeNESW: ["대각선방향크기조절2", "대각선2", "nesw", "diagonal2", "dgn2"]
    ]

    private static let displayKeywords: [AppLanguage: [CursorRole: [String]]] = [
        .korean: [
            .arrow: ["일반", "기본", "화살표"],
            .text: ["텍스트", "입력", "I빔"],
            .link: ["링크", "손가락", "포인팅"],
            .location: ["드래그", "복사", "위치"],
            .precision: ["정밀도", "십자선", "교차"],
            .move: ["이동", "드래그", "잡기"],
            .unavailable: ["사용 불가", "금지", "차단"],
            .busy: ["사용 중", "busy"],
            .working: ["백그라운드", "대기", "로딩"],
            .help: ["도움말", "물음표"],
            .handwriting: ["손글씨", "펜", "연필"],
            .person: ["셀", "사람 선택"],
            .alternate: ["바로가기", "별칭"],
            .verticalResize: ["수직", "상하"],
            .horizontalResize: ["수평", "좌우"],
            .diagonalResizeNWSE: ["대각선 1", "NWSE"],
            .diagonalResizeNESW: ["대각선 2", "NESW"]
        ],
        .english: [
            .arrow: ["arrow", "normal", "pointer"],
            .text: ["text", "ibeam", "input"],
            .link: ["link", "pointing hand", "pointer hand"],
            .location: ["drag", "copy", "location", "loc"],
            .precision: ["precision", "crosshair"],
            .move: ["move", "drag", "grab"],
            .unavailable: ["unavailable", "forbidden", "blocked"],
            .busy: ["busy", "in use"],
            .working: ["background", "wait", "loading", "working"],
            .help: ["help", "question"],
            .handwriting: ["handwriting", "pen", "pencil"],
            .person: ["cell", "person"],
            .alternate: ["alias", "alternate"],
            .verticalResize: ["vertical", "up/down", "vert"],
            .horizontalResize: ["horizontal", "left/right", "horz"],
            .diagonalResizeNWSE: ["diagonal 1", "nwse", "dgn1"],
            .diagonalResizeNESW: ["diagonal 2", "nesw", "dgn2"]
        ],
        .japanese: [
            .arrow: ["通常", "基本", "矢印"],
            .text: ["テキスト", "入力", "Iビーム"],
            .link: ["リンク", "ポインティングハンド"],
            .location: ["ドラッグ", "コピー", "位置"],
            .precision: ["精密", "十字線"],
            .move: ["移動", "ドラッグ", "つかむ"],
            .unavailable: ["使用不可", "禁止"],
            .busy: ["使用中", "ビジー"],
            .working: ["バックグラウンド", "待機", "読み込み"],
            .help: ["ヘルプ", "質問"],
            .handwriting: ["手書き", "ペン", "鉛筆"],
            .person: ["セル", "人物"],
            .alternate: ["エイリアス", "別名"],
            .verticalResize: ["垂直", "上下"],
            .horizontalResize: ["水平", "左右"],
            .diagonalResizeNWSE: ["斜め 1", "NWSE"],
            .diagonalResizeNESW: ["斜め 2", "NESW"]
        ],
        .simplifiedChinese: [
            .arrow: ["普通", "默认", "箭头"],
            .text: ["文本", "输入", "I形"],
            .link: ["链接", "指向手"],
            .location: ["拖动", "复制", "位置"],
            .precision: ["精确", "十字线"],
            .move: ["移动", "拖动", "抓取"],
            .unavailable: ["不可用", "禁止"],
            .busy: ["忙碌", "占用中"],
            .working: ["后台", "等待", "加载"],
            .help: ["帮助", "问号"],
            .handwriting: ["手写", "笔", "铅笔"],
            .person: ["单元格", "人物"],
            .alternate: ["别名", "替代"],
            .verticalResize: ["垂直", "上下"],
            .horizontalResize: ["水平", "左右"],
            .diagonalResizeNWSE: ["对角 1", "NWSE"],
            .diagonalResizeNESW: ["对角 2", "NESW"]
        ],
        .traditionalChinese: [
            .arrow: ["一般", "預設", "箭頭"],
            .text: ["文字", "輸入", "I 形"],
            .link: ["連結", "指向手"],
            .location: ["拖曳", "複製", "位置"],
            .precision: ["精確", "十字線"],
            .move: ["移動", "拖曳", "抓取"],
            .unavailable: ["不可用", "禁止"],
            .busy: ["忙碌", "使用中"],
            .working: ["背景", "等待", "載入"],
            .help: ["說明", "問號"],
            .handwriting: ["手寫", "筆", "鉛筆"],
            .person: ["儲存格", "人物"],
            .alternate: ["別名", "替代"],
            .verticalResize: ["垂直", "上下"],
            .horizontalResize: ["水平", "左右"],
            .diagonalResizeNWSE: ["對角 1", "NWSE"],
            .diagonalResizeNESW: ["對角 2", "NESW"]
        ],
        .german: [
            .arrow: ["Pfeil", "Standard", "Zeiger"],
            .text: ["Text", "Eingabe", "I-Balken"],
            .link: ["Link", "Zeigehand"],
            .location: ["Ziehen", "Kopieren", "Position"],
            .precision: ["Präzision", "Fadenkreuz"],
            .move: ["Bewegen", "Ziehen", "Greifen"],
            .unavailable: ["Nicht verfügbar", "Verboten"],
            .busy: ["Beschäftigt", "In Benutzung"],
            .working: ["Hintergrund", "Warten", "Laden"],
            .help: ["Hilfe", "Frage"],
            .handwriting: ["Handschrift", "Stift", "Bleistift"],
            .person: ["Zelle", "Person"],
            .alternate: ["Alias", "Alternativ"],
            .verticalResize: ["Vertikal", "Oben/Unten"],
            .horizontalResize: ["Horizontal", "Links/Rechts"],
            .diagonalResizeNWSE: ["Diagonal 1", "NWSE"],
            .diagonalResizeNESW: ["Diagonal 2", "NESW"]
        ],
        .french: [
            .arrow: ["flèche", "normal", "pointeur"],
            .text: ["texte", "saisie", "I-beam"],
            .link: ["lien", "main pointée"],
            .location: ["glisser", "copie", "position"],
            .precision: ["précision", "croix"],
            .move: ["déplacer", "glisser", "saisir"],
            .unavailable: ["indisponible", "interdit"],
            .busy: ["occupé", "en cours"],
            .working: ["arrière-plan", "attente", "chargement"],
            .help: ["aide", "question"],
            .handwriting: ["manuscrit", "stylo", "crayon"],
            .person: ["cellule", "personne"],
            .alternate: ["alias", "alternatif"],
            .verticalResize: ["vertical", "haut/bas"],
            .horizontalResize: ["horizontal", "gauche/droite"],
            .diagonalResizeNWSE: ["diagonale 1", "NWSE"],
            .diagonalResizeNESW: ["diagonale 2", "NESW"]
        ],
        .spanish: [
            .arrow: ["flecha", "normal", "puntero"],
            .text: ["texto", "entrada", "I-beam"],
            .link: ["enlace", "mano apuntadora"],
            .location: ["arrastrar", "copiar", "ubicación"],
            .precision: ["precisión", "cruz"],
            .move: ["mover", "arrastrar", "agarrar"],
            .unavailable: ["no disponible", "prohibido"],
            .busy: ["ocupado", "en uso"],
            .working: ["segundo plano", "espera", "cargando"],
            .help: ["ayuda", "pregunta"],
            .handwriting: ["escritura", "pluma", "lápiz"],
            .person: ["celda", "persona"],
            .alternate: ["alias", "alternativo"],
            .verticalResize: ["vertical", "arriba/abajo"],
            .horizontalResize: ["horizontal", "izquierda/derecha"],
            .diagonalResizeNWSE: ["diagonal 1", "NWSE"],
            .diagonalResizeNESW: ["diagonal 2", "NESW"]
        ],
        .portugueseBrazil: [
            .arrow: ["seta", "normal", "ponteiro"],
            .text: ["texto", "entrada", "I-beam"],
            .link: ["link", "mão apontando"],
            .location: ["arrastar", "copiar", "posição"],
            .precision: ["precisão", "cruz"],
            .move: ["mover", "arrastar", "agarrar"],
            .unavailable: ["indisponível", "proibido"],
            .busy: ["ocupado", "em uso"],
            .working: ["segundo plano", "espera", "carregando"],
            .help: ["ajuda", "pergunta"],
            .handwriting: ["escrita", "caneta", "lápis"],
            .person: ["célula", "pessoa"],
            .alternate: ["alias", "alternativo"],
            .verticalResize: ["vertical", "cima/baixo"],
            .horizontalResize: ["horizontal", "esquerda/direita"],
            .diagonalResizeNWSE: ["diagonal 1", "NWSE"],
            .diagonalResizeNESW: ["diagonal 2", "NESW"]
        ],
        .italian: [
            .arrow: ["freccia", "normale", "puntatore"],
            .text: ["testo", "input", "I-beam"],
            .link: ["link", "mano puntatore"],
            .location: ["trascina", "copia", "posizione"],
            .precision: ["precisione", "mirino"],
            .move: ["sposta", "trascina", "afferra"],
            .unavailable: ["non disponibile", "vietato"],
            .busy: ["occupato", "in uso"],
            .working: ["sfondo", "attesa", "caricamento"],
            .help: ["aiuto", "domanda"],
            .handwriting: ["scrittura", "penna", "matita"],
            .person: ["cella", "persona"],
            .alternate: ["alias", "alternativo"],
            .verticalResize: ["verticale", "su/giù"],
            .horizontalResize: ["orizzontale", "sinistra/destra"],
            .diagonalResizeNWSE: ["diagonale 1", "NWSE"],
            .diagonalResizeNESW: ["diagonale 2", "NESW"]
        ],
        .russian: [
            .arrow: ["стрелка", "обычный", "указатель"],
            .text: ["текст", "ввод", "I-луч"],
            .link: ["ссылка", "указывающая рука"],
            .location: ["перетаскивание", "копия", "позиция"],
            .precision: ["точность", "перекрестие"],
            .move: ["перемещение", "перетаскивание", "захват"],
            .unavailable: ["недоступно", "запрещено"],
            .busy: ["занято", "используется"],
            .working: ["фон", "ожидание", "загрузка"],
            .help: ["помощь", "вопрос"],
            .handwriting: ["рукописный", "ручка", "карандаш"],
            .person: ["ячейка", "человек"],
            .alternate: ["псевдоним", "альтернативный"],
            .verticalResize: ["вертикально", "вверх/вниз"],
            .horizontalResize: ["горизонтально", "влево/вправо"],
            .diagonalResizeNWSE: ["диагональ 1", "NWSE"],
            .diagonalResizeNESW: ["диагональ 2", "NESW"]
        ]
    ]

    private static func aliasStems(for role: CursorRole) -> Set<String> {
        Set(exactAliases[role, default: []].map {
            normalizedKeyword($0)
        })
    }

    private static func orderedKeywords(for role: CursorRole) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for keyword in exactAliases[role, default: []] + fuzzyKeywords[role, default: []] {
            let normalized = normalizedKeyword(keyword)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { continue }
            ordered.append(keyword)
        }

        return ordered
    }

    private static func normalizedKeyword(_ keyword: String) -> String {
        keyword
            .precomposedStringWithCanonicalMapping
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func canonicalFileName(_ value: String) -> String {
        value
            .precomposedStringWithCanonicalMapping
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private func canonicalStem(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .precomposedStringWithCanonicalMapping
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "독케익_", with: "")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func fallbackArrowCandidate(from candidates: [URL], excluding used: Set<URL>) -> URL? {
        let remaining = candidates.filter { !used.contains($0.standardizedFileURL) }
        guard !remaining.isEmpty else { return nil }

        let preferred = ["pointer", "normal", "default", "arrow", "basic", "main"]
        if let named = remaining.first(where: { url in
            let stem = canonicalStem(url)
            return preferred.contains(where: { stem.contains($0) })
        }) {
            return named
        }

        return remaining.sorted { canonicalStem($0) < canonicalStem($1) }.first
    }
}
