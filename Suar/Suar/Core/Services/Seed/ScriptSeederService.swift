//
//  ScriptSeederService.swift
//  Suar
//
//  Created by DIMAS DAFFA ERNANDA on 10/09/26.
//

import Foundation
import SwiftData

public final class ScriptSeederService: ScriptSeederServiceProtocol {
    private static let hasSeededKey = "hasSeededDummyScript_v1"

    private let repository: ScriptRepositoryProtocol

    public init(repository: ScriptRepositoryProtocol) {
        self.repository = repository
    }

    public func seedIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: Self.hasSeededKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.hasSeededKey)

        do {
            try await repository.save(script: makeDummyScript())
            print("[Seed] Berhasil men-seed naskah dummy.")
        } catch {
            UserDefaults.standard.set(false, forKey: Self.hasSeededKey)
            print("[Seed] Gagal: \(error.localizedDescription)")
        }
    }

    private func makeDummyScript() -> Script {
        let scenes: [(scene: String, lines: [(type: ScriptBlockType, char: String?, cue: String?, content: String)])] = [
            ("Bagian Pertama", [
                (.stageDirection, nil, nil, "Ruang tunggu sebuah rumah sakit. Kursi-kursi plastik berjejer di lorong. Lampu neon berkedip pelan."),
                (.dialogue, "WANITA", nil, "Kenapa kamu tidak pernah mau cerita sebenarnya?"),
                (.dialogue, "PRIA", "(duduk tenang)", "Karena kadang diam lebih jujur daripada kata-kata."),
                (.stageDirection, nil, nil, "Suara langkah kaki di lorong. Seorang perawat lewat dengan troli obat.")
            ]),
            ("Bagian Kedua", [
                (.dialogue, "WANITA", "(membuka selembar surat)", "Ini... ini surat dari dia?"),
                (.dialogue, "PRIA", "(mengangguk pelan)", "Dia menitipkan ini sebelum pergi."),
                (.stageDirection, nil, nil, "Hujan mulai turun di luar jendela. Udara terasa lebih berat.")
            ]),
            ("Bagian Ketiga", [
                (.dialogue, "DOKTER", "(masuk dengan langkah cepat)", "Maaf saya terlambat. Operasi berjalan lancar tapi... ada komplikasi."),
                (.stageDirection, nil, nil, "Semua mata tertuju pada dokter. Kegelisahan merebak di ruangan."),
                (.dialogue, "WANITA", "(berbisik)", "Komplikasi apa?")
            ]),
            ("Bagian Keempat", [
                (.dialogue, "DOKTER", nil, "Jantungnya lemah. Kami sudah melakukan yang terbaik."),
                (.stageDirection, nil, nil, "Keheningan yang panjang. Wanita meremas tangan pria."),
                (.dialogue, "PRIA", "(memejamkan mata)", "Setidaknya... dia pergi dengan tenang.")
            ]),
            ("Bagian Kelima", [
                (.stageDirection, nil, nil, "Malam tiba. Lampu ruang tunggu dipadamkan satu per satu."),
                (.dialogue, "WANITA", "(berdiri, menatap jendela)", "Aku tidak bisa melupakan hari ini."),
                (.dialogue, "PRIA", "(menggenggam tangannya)", "Dan aku tidak akan membiarkanmu sendiri."),
                (.stageDirection, nil, nil, "Mereka berjalan bersama menyusuri lorong gelap, meninggalkan ruang tunggu untuk selamanya.")
            ])
        ]

        var allPages: [ScriptPage] = []
        var orderIndex = 1

        for (pageNum, scene) in scenes.enumerated() {
            var blocks: [ScriptBlock] = []

            let header = ScriptBlock(
                orderIndex: orderIndex,
                blockType: .sceneHeader,
                content: scene.scene,
                startPageNumber: pageNum + 1
            )
            blocks.append(header)
            orderIndex += 1

            for line in scene.lines {
                let block = ScriptBlock(
                    orderIndex: orderIndex,
                    blockType: line.type,
                    characterName: line.char,
                    content: line.content,
                    cueDescription: line.cue,
                    startPageNumber: pageNum + 1
                )
                blocks.append(block)
                orderIndex += 1
            }

            let page = ScriptPage(
                pageNumber: pageNum + 1,
                rawExtractedText: "",
                blocks: blocks
            )
            allPages.append(page)
        }

        return Script(
            title: "Ruang Tunggu",
            createdAt: Date(),
            lastReadPage: 1,
            pageCount: allPages.count,
            sourceFileName: "ruang-tunggu-dummy",
            pages: allPages
        )
    }
}
