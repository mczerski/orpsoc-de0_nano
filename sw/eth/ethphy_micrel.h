
	/* Micrel KSZ8001 PHY configuration */
	/* Register addresses */
#define MICREL_KSZ8001_BCR_ADR 0x0 /* Basic Control Register */
#define MICREL_KSZ8001_BSR_ADR 0x1 /* Basic Status Register */
#define MICREL_KSZ8001_PI1_ADR 0x2 /* PHY Identifier I */
#define MICREL_KSZ8001_PI2_ADR 0x3 /* PHY Identifier II */
#define MICREL_KSZ8001_ANAR_ADR 0x4 /* Auto-Negotiation Advertisement Register */
#define MICREL_KSZ8001_ANLPAR_ADR 0x5 /* Auto-Negotiation Link Partner Ability Register */
#define MICREL_KSZ8001_ANER_ADR 0x6 /* Auto-Negotiation Expansion Register */
#define MICREL_KSZ8001_ANNPR_ADR 0x7 /* Auto-Negotiation Next Page Register */
#define MICREL_KSZ8001_LPNPA_ADR 0x8 /* Link Partner Next Page Ability */
#define MICREL_KSZ8001_RXERCR_ADR 0x15 /* RXER Counter Register */
#define MICREL_KSZ8001_ICSR_ADR 0x1b /* Interrupt Control/Status Register */
#define MICREL_KSZ8001_LMDCSR_ADR 0x1d /* LinkMD Control/Status Register */
#define MICREL_KSZ8001_PCR_ADR 0x1e /* PHY Control Register */
#define MICREL_KSZ8001_100BTPCR_ADR 0x1f /* 100BASE-TX PHY Control Register */

	/* Basic Control Register bits */
#define MICREL_KSZ8001_BCR_DIS_TRANS (1<<0) /* Disable Transmitter */
#define MICREL_KSZ8001_BCR_COL_TEST (1<<7) /* Collision Test */
#define MICREL_KSZ8001_BCR_DUP (1<<8) /* Duplex Mode */
#define MICREL_KSZ8001_BCR_RST_AUTONEG (1<<9) /* Restart Auto-Negotiation */
#define MICREL_KSZ8001_BCR_ISOLATE (1<<10) /* Isolate */
#define MICREL_KSZ8001_BCR_PWR_DOWN (1<<11) /* Power Down */
#define MICREL_KSZ8001_BCR_AUTONEG_EN (1<<12) /* Auto-Negotiation Enable */
#define MICREL_KSZ8001_BCR_SPD_SEL (1<<13) /* Speed Select */
#define MICREL_KSZ8001_BCR_LOOP_BACK (1<<14) /* Loop Back */
#define MICREL_KSZ8001_BCR_RESET (1<<15)/* Reset */

	/* Basic Status Register bits */
#define MICREL_KSZ8001_BSR_EC (1<<0) /* Extended Capability */
#define MICREL_KSZ8001_BSR_JD (1<<1) /* Jabber Detect */
#define MICREL_KSZ8001_BSR_LS (1<<2) /* Link Status */
#define MICREL_KSZ8001_BSR_AUTONEG_ABLE (1<<3) /* Auto-Negotiation Ability */
#define MICREL_KSZ8001_BSR_RF (1<<4) /* Remote Fault */
#define MICREL_KSZ8001_BSR_AUTONEG_CMPLT (1<<5) /* Auto-Negotiation Complete */
#define MICREL_KSZ8001_BSR_NP (1<<6) /* No Premble */
#define MICREL_KSZ8001_BSR_10BTHD (1<<11) /* 10BASE-T Half Duplex */
#define MICREL_KSZ8001_BSR_10BTFD (1<<12) /* 10BASE-T Full Duplex */
#define MICREL_KSZ8001_BSR_100BTXHD (1<<13) /* 100BASE-TX Half Duplex */
#define MICREL_KSZ8001_BSR_100BTXFD (1<<14) /* 100BASE-TX Full Duplex */
#define MICREL_KSZ8001_BSR_100BT4 (1<<15) /* 100BASE-T4 Capable */
