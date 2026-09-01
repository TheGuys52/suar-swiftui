//
//  MockScriptRepository.swift
//  Suar
//
//  Created by arihasan256 on 26/08/26.
//

import Foundation

let page1 = ScriptPageMock(
    pageNumber: 1,
    elements: [
        ScriptElementMock(type: .text, content: "Ruang Tunggu", order: 0),
        ScriptElementMock(type: .text, content: "Muhammad Raihan", order: 1),
        ScriptElementMock(
            type: .text,
            content: "~Sebuah lakon drama~",
            order: 2
        )
    ]
)

let page2 = ScriptPageMock(
    pageNumber: 2,
    elements: [
        ScriptElementMock(
            type: .text,
            content: "Lakon Ruang Tunggu",
            order: 0
        ),
        ScriptElementMock(
            type: .text,
            content: "Dramatis Personae:\n" +
                "1. Pria – pemuda biasa-biasa saja, nyaris tidak punya apa-apa, miskin.\n" +
                "2. Wanita – seorang ibu yang sedang kehilangan anaknya\n" +
                "3. Pria Tua – pemberi wejangan, sosok arif dan bijaksana",
            order: 1
        ),
        ScriptElementMock(
            type: .text,
            content: "Bagian Pertama",
            order: 2
        ),
        ScriptElementMock(
            type: .description,
            content: """
            HAL YANG PERTAMA MUNCUL ADALAH SUARA ORANG-ORANG:
            KERAMAIAN. ATAU LEBIH TEPATNYA, TERIAKAN-TERIAKAN YANG KACAU
            DAN BERISIK. SEPERTI ADA SEKUMPULAN BESAR ORANG YANG SEDANG
            MENERIAKI SESUATU. NAMUN SITUASI PANGGUNG SANGATLAH GELAP.
            BUNYI-BUNYIAN ITU AMAT BERISIK. SEPERTI KERUMUNAN MASSA YANG
            TIDAK KENAL LELAH MENERIAKKAN APA PUN YANG KELUAR DARI MULUT
            MEREKA. KEMUDIAN KEGELAPAN PERLAHAN DIUSIR PERGI, CAHAYA
            MENYERUAK. LAMPU MENYALA SATU PER SATU. TAMPAK LATAR RUANG
            TUNGGU. WUJUDNYA SERUPA KORIDOR YANG PANJANG, DENGAN ENAM
            BUAH BANGKU TUNGGU KAYU YANG TAMPAK DINGIN.
            """,
            order: 3
        ),
        ScriptElementMock(
            type: .description,
            content: "Bunyi-bunyian itu amat berisik. Seperti kerumunan massa yang " +
                "tidak kenal lelah meneriakkan apa pun yang keluar dari mulut mereka. " +
                "Kemudian kegelapan perlahan diusir pergi, cahaya menyeruak. " +
                "Lampu menyala satu per satu. Tampak latar ruang tunggu. " +
                "Wujudnya serupa koridor yang panjang, dengan enam buah bangku tunggu " +
                "kayu yang tampak dingin.",
            order: 4
        ),
        ScriptElementMock(
            type: .description,
            content: "Di atasnya, lampu-lampu pijar menyala dan menggantung tak berdaya. " +
                "Dinding di sisi belakang berwarna hijau kelabu. " +
                "Terdapat sejumlah poster iklan, berita orang hilang, dan " +
                "grafiti-grafiti kotor yang serampangan. Dari samping kanan, " +
                "seorang pemuda berjalan dengan hati-hati. Tampangnya kotor, gelisah, " +
                "sorot matanya mengamati sekeliling dengan rasa takut yang kentara. " +
                "Sejenak dia berhenti, lalu jalan lagi, lalu berhenti, lalu jalan lagi.",
            order: 5
        ),
        ScriptElementMock(
            type: .description,
            content: "Dia berhenti sepenuhnya di salah satu bangku. " +
                "Lalu dia duduk. Kedua tangannya memegang sebuah tas kulit. " +
                "Napasnya terengah-engah.",
            order: 6
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "PRIA: (mengelus dada) Ya Tuhan. Oh ya Tuhaan. Tuhan atas " +
                "segala duka. Tuhan atas semua jenis rasa sakit. " +
                "Tuhan yang kehadirannya bagai musim hujan di kala panas menyengat, " +
                "dan bagai angin kering yang memecah musim penghujan. " +
                "Ya Tuhan, ya Tuhan, ya Tuhaann. Tuhanku, Tuhanku, Tuhanku… " +
                "(menundukkan kepala dengan lemas)",
            order: 7
        ),
        ScriptElementMock(
            type: .description,
            content: "Sesaat kemudian sesuatu terjadi. Lampu-lampu meremang, " +
                "kedip-kedip. Suara arus listrik berdenyut dengan janggal. " +
                "Pria terkejut, bingung, bangkit dan sejenak mengamati peristiwa itu " +
                "disertai tanda tanya besar.",
            order: 8
        )
    ]
)

let page3 = ScriptPageMock(
    pageNumber: 3,
    elements: [
        ScriptElementMock(
            type: .description,
            content: "Muncul suara-suara abstrak. Teriakan tanpa lafal, tanpa ejaan, " +
                "benar-benar kacau. Hanya bualan, berisik sekali. " +
                "Si Pria ketakutan bukan main.",
            order: 0
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "PRIA: (sadar, gelisah) Oh, astaga. Ya Tuhan. Ya Tuhan, oh, " +
                "astaga. Siapa itu? Siapa di sana??",
            order: 1
        ),
        ScriptElementMock(
            type: .description,
            content: "Suara-suara berteriak serupa teror yang mencekam. " +
                "Si Pria berlarian, kebingungan. Tak tahu harus ke mana. " +
                "Tanpa sadar, pria muda meringkuk di dekat tempat duduk " +
                "seperti hewan yang ketakutan.",
            order: 2
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "PRIA: (ketakutan) Ya Tuhan ampunilah aku! Ampunilah segala " +
                "kesilapan, kesalahan, dan dosaku. Aku tidak sempurna. " +
                "Aku tidaklah sempurna! Aku berlumur dosa! Ampun! Cukup! Cukuuup!!!",
            order: 3
        ),
        ScriptElementMock(
            type: .description,
            content: "Tak lama, suara-suara mulai menghilang. Dari jauh, terdengar " +
                "suara keributan disertai teriakan seorang wanita. " +
                "Lampu menyala kedip-kedip lagi, dan si Pria menyadarinya. " +
                "Mimik wajahnya berusaha mencari tahu.",
            order: 4
        ),
        ScriptElementMock(
            type: .description,
            content: "Tak lama, muncul seorang Wanita dari sisi panggung. " +
                "Tampang dan penampilannya kacau, sambil memegang sebuah tas besar " +
                "yang terbuka, berisi banyak baju. Di tangannya yang lain, " +
                "ada sebuah panci yang dipukul-pukulkan ke lantai. Suaranya berisik. " +
                "Tak henti-hentinya berteriak. Perlahan, ia mulai mendekati si Pria.",
            order: 5
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "WANITA: (berteriak-teriak) Anakku?? Di mana kau?? Hei! " +
                "Anakku…? (memukul-mukul panci ke lantai)",
            order: 6
        ),
        ScriptElementMock(
            type: .description,
            content: "Ketika sudah di dekat Pria, Wanita itu memukulkan pancinya " +
                "amat keras ke lantai. Suaranya menggelegar ke seluruh penjuru. " +
                "Si Pria kaget, terperanjat ke belakang, nyaris jungkir balik.",
            order: 7
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "WANITA: (bertanya) Apa kau melihat seorang anak kecil, berusia " +
                "segini (mengangkat jari tangannya), dengan tinggi segini? " +
                "(mengukur setinggi paha)",
            order: 8
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "PRIA: (menggeleng kencang)",
            order: 9
        ),
        ScriptElementMock(
            type: .dialogue,
            content: "WANITA: (tepuk jidat) Aduh, ke mana sih anak itu sebenarnya. " +
                "Dicari di segala tempat tidak juga ketemu. Inilah sebabnya aku " +
                "benci punya anak. Harus mengurus, mengawasi, tidak boleh ceroboh.",
            order: 10
        )
    ]
)

let scriptMock = ScriptMock(
    title: "Ruang Tunggu",
    author: "Muhammad Raihan",
    pages: [page1, page2, page3]
)
