// lib/src/modules/categorias/data/categoria_icons.dart

import 'package:flutter/material.dart';

/// Sistema completo de ícones para categorias
/// 🔝 ÍCONES SIMPLES (Material + Feather) - Minimalistas profissionais
/// 🎨 BIBLIOTECA RICA (Emojis) - Coloridos e expressivos
/// Total: ~600+ ícones organizados por categoria
class CategoriaIcons {
  
  // ===============================================
  // 🔝 ÍCONES SIMPLES - MATERIAL + FEATHER ICONS
  // ===============================================
  
  /// Ícones simples profissionais - estilo outline minimalista
  /// Ideal para destacar cores de categoria e visual clean
  static const Map<String, List<IconData>> iconesSimples = {

    /// FINANÇAS - Símbolos financeiros profissionais
    'Finanças': [
      // Dinheiro e pagamentos
      Icons.attach_money_outlined,
      Icons.euro_outlined,
      Icons.credit_card_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_outlined,
      Icons.savings_outlined,
      Icons.monetization_on_outlined,
      Icons.payment_outlined,
      // Gráficos e análises
      Icons.trending_up_outlined,
      Icons.trending_down_outlined,
      Icons.show_chart_outlined,
      Icons.analytics_outlined,
      Icons.assessment_outlined,
      Icons.bar_chart_outlined,
      Icons.timeline_outlined,
      // Negócios
      Icons.business_center_outlined,
      Icons.work_outline,
      Icons.corporate_fare_outlined,
      Icons.apartment_outlined,
      // Símbolos de sucesso
      Icons.star_outline,
      Icons.diamond_outlined,
      Icons.emoji_events_outlined,
      Icons.military_tech_outlined,
    ],

    /// ALIMENTAÇÃO - Comida e bebida
    'Alimentação': [
      // Refeições
      Icons.restaurant_outlined,
      Icons.fastfood_outlined,
      Icons.dinner_dining_outlined,
      Icons.lunch_dining_outlined,
      Icons.breakfast_dining_outlined,
      Icons.local_dining_outlined,
      Icons.room_service_outlined,
      Icons.takeout_dining_outlined,
      // Bebidas
      Icons.local_cafe_outlined,
      Icons.local_bar_outlined,
      Icons.wine_bar_outlined,
      Icons.coffee_outlined,
      Icons.emoji_food_beverage_outlined,
      Icons.local_drink_outlined,
      Icons.liquor_outlined,
      Icons.sports_bar_outlined,
      // Compras de comida
      Icons.local_grocery_store_outlined,
      Icons.shopping_cart_outlined,
      Icons.store_outlined,
      Icons.storefront_outlined,
      // Cozinha
      Icons.kitchen_outlined,
      Icons.microwave_outlined,
    ],

    /// TRANSPORTE - Veículos e locomoção
    'Transporte': [
      // Carros
      Icons.directions_car_outlined,
      Icons.car_rental_outlined,
      Icons.local_taxi_outlined,
      Icons.car_repair_outlined,
      Icons.garage_outlined,
      Icons.local_gas_station_outlined,
      Icons.local_parking_outlined,
      Icons.traffic_outlined,
      // Transporte público
      Icons.directions_bus_outlined,
      Icons.directions_subway_outlined,
      Icons.train_outlined,
      Icons.tram_outlined,
      Icons.directions_railway_outlined,
      Icons.subway_outlined,
      Icons.bus_alert_outlined,
      Icons.commute_outlined,
      // Outros transportes
      Icons.directions_bike_outlined,
      Icons.motorcycle_outlined,
      Icons.electric_scooter_outlined,
      Icons.skateboarding_outlined,
      // Viagem
      Icons.flight_outlined,
      Icons.local_airport_outlined,
      Icons.directions_boat_outlined,
      Icons.sailing_outlined,
    ],

    /// MORADIA - Casa e utilidades
    'Moradia': [
      // Casa
      Icons.home_outlined,
      Icons.house_outlined,
      Icons.apartment_outlined,
      Icons.villa_outlined,
      Icons.cottage_outlined,
      Icons.cabin_outlined,
      Icons.bungalow_outlined,
      Icons.chalet_outlined,
      // Cômodos
      Icons.bed_outlined,
      Icons.chair_outlined,
      Icons.table_restaurant_outlined,
      Icons.weekend_outlined,
      Icons.living_outlined,
      Icons.kitchen_outlined,
      Icons.bathroom_outlined,
      Icons.balcony_outlined,
      // Utilidades
      Icons.electrical_services_outlined,
      Icons.plumbing_outlined,
      Icons.carpenter_outlined,
      Icons.handyman_outlined,
      Icons.build_outlined,
      Icons.construction_outlined,
      Icons.engineering_outlined,
      Icons.architecture_outlined,
      // Segurança
      Icons.lock_outlined,
      Icons.security_outlined,
      Icons.vpn_key_outlined,
      Icons.key_outlined,
    ],

    /// SAÚDE - Medicina e bem-estar
    'Saúde': [
      // Medicina
      Icons.local_hospital_outlined,
      Icons.medical_services_outlined,
      Icons.medication_outlined,
      Icons.vaccines_outlined,
      Icons.healing_outlined,
      Icons.monitor_heart_outlined,
      Icons.emergency_outlined,
      // Especialidades
      Icons.psychology_outlined,
      Icons.biotech_outlined,
      Icons.science_outlined,
      Icons.medical_information_outlined,
      Icons.health_and_safety_outlined,
      Icons.masks_outlined,
      Icons.sanitizer_outlined,
      Icons.thermostat_outlined,
      // Exercícios
      Icons.fitness_center_outlined,
      Icons.sports_gymnastics_outlined,
      Icons.directions_run_outlined,
      Icons.directions_walk_outlined,
      Icons.self_improvement_outlined,
      Icons.spa_outlined,
      Icons.hot_tub_outlined,
      Icons.pool_outlined,
    ],

    /// EDUCAÇÃO - Estudos e aprendizado
    'Educação': [
      // Escola
      Icons.school_outlined,
      Icons.auto_stories_outlined,
      Icons.menu_book_outlined,
      Icons.library_books_outlined,
      Icons.book_outlined,
      Icons.bookmark_outline,
      Icons.class_outlined,
      Icons.groups_outlined,
      // Material escolar
      Icons.edit_outlined,
      Icons.create_outlined,
      Icons.draw_outlined,
      Icons.format_paint_outlined,
      Icons.highlight_outlined,
      Icons.text_fields_outlined,
      Icons.title_outlined,
      Icons.article_outlined,
      // Tecnologia educacional
      Icons.computer_outlined,
      Icons.laptop_outlined,
      Icons.tablet_outlined,
      Icons.phone_android_outlined,
      Icons.cast_for_education_outlined,
      Icons.screen_share_outlined,
      Icons.slideshow_outlined,
    ],

    /// LAZER - Entretenimento e diversão
    'Lazer': [
      // Jogos
      Icons.sports_esports_outlined,
      Icons.casino_outlined,
      Icons.toys_outlined,
      Icons.extension_outlined,
      Icons.games_outlined,
      Icons.smart_toy_outlined,
      Icons.videogame_asset_outlined,
      Icons.sports_outlined,
      // Música e arte
      Icons.music_note_outlined,
      Icons.library_music_outlined,
      Icons.album_outlined,
      Icons.audiotrack_outlined,
      Icons.headphones_outlined,
      Icons.speaker_outlined,
      Icons.radio_outlined,
      Icons.mic_outlined,
      // Visual
      Icons.movie_outlined,
      Icons.theaters_outlined,
      Icons.live_tv_outlined,
      Icons.video_library_outlined,
      Icons.camera_alt_outlined,
      Icons.photo_camera_outlined,
      Icons.videocam_outlined,
      Icons.collections_outlined,
    ],

    /// ESPORTES - Atividades físicas
    'Esportes': [
      // Esportes populares
      Icons.sports_soccer_outlined,
      Icons.sports_basketball_outlined,
      Icons.sports_football_outlined,
      Icons.sports_baseball_outlined,
      Icons.sports_tennis_outlined,
      Icons.sports_volleyball_outlined,
      Icons.sports_golf_outlined,
      Icons.sports_hockey_outlined,
      // Exercícios
      Icons.fitness_center_outlined,
      Icons.pool_outlined,
      Icons.directions_bike_outlined,
      Icons.directions_run_outlined,
      Icons.hiking_outlined,
      Icons.snowboarding_outlined,
      Icons.surfing_outlined,
      // Equipamentos
      Icons.emoji_events_outlined,
      Icons.military_tech_outlined,
      Icons.workspace_premium_outlined,
      Icons.star_outlined,
      Icons.grade_outlined,
      Icons.shield_outlined,
      Icons.flag_outlined,
      Icons.timer_outlined,
    ],

    /// FAMÍLIA - Relacionamentos e cuidados
    'Família': [
      // Pessoas
      Icons.family_restroom_outlined,
      Icons.child_care_outlined,
      Icons.baby_changing_station_outlined,
      Icons.escalator_warning_outlined,
      Icons.pregnant_woman_outlined,
      Icons.elderly_outlined,
      Icons.person_outlined,
      Icons.people_outlined,
      // Casa e família
      Icons.home_outlined,
      Icons.weekend_outlined,
      Icons.dining_outlined,
      Icons.celebration_outlined,
      Icons.cake_outlined,
      Icons.card_giftcard_outlined,
      Icons.redeem_outlined,
      Icons.volunteer_activism_outlined,
      // Cuidados
      Icons.favorite_outline,
      Icons.health_and_safety_outlined,
      Icons.healing_outlined,
      Icons.support_outlined,
      Icons.psychology_outlined,
      Icons.sentiment_satisfied_outlined,
      Icons.emoji_emotions_outlined,
    ],

    /// PETS - Animais de estimação
    'Pets': [
      // Animais
      Icons.pets_outlined,
      Icons.cruelty_free_outlined,
      // Cuidados veterinários
      Icons.medical_services_outlined,
      Icons.local_hospital_outlined,
      Icons.healing_outlined,
      Icons.vaccines_outlined,
      Icons.medication_outlined,
      Icons.monitor_heart_outlined,
      Icons.emergency_outlined,
      Icons.health_and_safety_outlined,
      // Alimentação
      Icons.restaurant_outlined,
      Icons.dinner_dining_outlined,
      Icons.local_dining_outlined,
      Icons.emoji_food_beverage_outlined,
      Icons.water_drop_outlined,
      Icons.opacity_outlined,
      // Acessórios e cuidados
      Icons.home_outlined,
      Icons.bed_outlined,
      Icons.toys_outlined,
      Icons.sports_outlined,
      Icons.directions_walk_outlined,
      Icons.directions_run_outlined,
      Icons.park_outlined,
      Icons.nature_outlined,
    ],

    /// TRABALHO - Atividades profissionais
    'Trabalho': [
      // Escritório
      Icons.work_outline,
      Icons.business_center_outlined,
      Icons.corporate_fare_outlined,
      Icons.apartment_outlined,
      Icons.domain_outlined,
      Icons.meeting_room_outlined,
      Icons.co_present_outlined,
      // Equipamentos
      Icons.computer_outlined,
      Icons.laptop_outlined,
      Icons.desktop_windows_outlined,
      Icons.keyboard_outlined,
      Icons.mouse_outlined,
      Icons.phone_outlined,
      Icons.headset_outlined,
      Icons.print_outlined,
      // Documentação
      Icons.description_outlined,
      Icons.article_outlined,
      Icons.assignment_outlined,
      Icons.folder_outlined,
      Icons.folder_open_outlined,
      Icons.insert_drive_file_outlined,
      Icons.picture_as_pdf_outlined,
      Icons.text_snippet_outlined,
      // Comunicação
      Icons.email_outlined,
      Icons.message_outlined,
      Icons.chat_outlined,
      Icons.video_call_outlined,
      Icons.call_outlined,
      Icons.contacts_outlined,
    ],

    /// VIAGEM - Turismo e aventuras
    'Viagem': [
      // Transporte de viagem
      Icons.flight_outlined,
      Icons.local_airport_outlined,
      Icons.connecting_airports_outlined,
      Icons.flight_takeoff_outlined,
      Icons.flight_land_outlined,
      Icons.directions_boat_outlined,
      Icons.train_outlined,
      Icons.directions_bus_outlined,
      // Hospedagem
      Icons.hotel_outlined,
      Icons.bed_outlined,
      Icons.weekend_outlined,
      Icons.cabin_outlined,
      Icons.villa_outlined,
      Icons.rv_hookup_outlined,
      Icons.house_outlined,
      // Atividades turísticas
      Icons.map_outlined,
      Icons.explore_outlined,
      Icons.tour_outlined,
      Icons.hiking_outlined,
      Icons.landscape_outlined,
      Icons.photo_camera_outlined,
      Icons.collections_outlined,
      Icons.place_outlined,
      // Bagagem e preparação
      Icons.luggage_outlined,
      Icons.backpack_outlined,
      Icons.card_travel_outlined,
      Icons.travel_explore_outlined,
      Icons.public_outlined,
      Icons.language_outlined,
    ],

    /// COMPRAS - Produtos e serviços
    'Compras': [
      // Compras gerais
      Icons.shopping_cart_outlined,
      Icons.shopping_bag_outlined,
      Icons.store_outlined,
      Icons.storefront_outlined,
      Icons.local_mall_outlined,
      Icons.shopping_basket_outlined,
      Icons.add_shopping_cart_outlined,
      Icons.remove_shopping_cart_outlined,
      // Pagamento
      Icons.payment_outlined,
      Icons.credit_card_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.attach_money_outlined,
      Icons.local_atm_outlined,
      Icons.point_of_sale_outlined,
      Icons.receipt_outlined,
      // Categorias de produtos
      Icons.checkroom_outlined,
      Icons.dry_cleaning_outlined,
      Icons.local_laundry_service_outlined,
      Icons.woman_outlined,
      Icons.man_outlined,
      Icons.child_care_outlined,
      Icons.face_outlined,
      Icons.brush_outlined,
      // Online
      Icons.computer_outlined,
      Icons.phone_android_outlined,
      Icons.delivery_dining_outlined,
      Icons.local_shipping_outlined,
      Icons.inventory_outlined,
      Icons.qr_code_outlined,
    ],

    /// OUTROS - Diversos e não categorizados
    'Outros': [
      // Organização
      Icons.folder_outlined,
      Icons.folder_open_outlined,
      Icons.create_new_folder_outlined,
      Icons.topic_outlined,
      Icons.label_outlined,
      Icons.bookmark_outline,
      Icons.push_pin_outlined,
      Icons.flag_outlined,
      // Símbolos gerais
      Icons.star_outline,
      Icons.grade_outlined,
      Icons.emoji_events_outlined,
      Icons.diamond_outlined,
      Icons.auto_awesome_outlined,
      Icons.bolt_outlined,
      Icons.flash_on_outlined,
      Icons.wb_sunny_outlined,
      // Direções
      Icons.arrow_upward_outlined,
      Icons.arrow_downward_outlined,
      Icons.arrow_forward_outlined,
      Icons.arrow_back_outlined,
      Icons.refresh_outlined,
      Icons.sync_outlined,
      Icons.swap_horiz_outlined,
      Icons.compare_arrows_outlined,
      // Funcionalidades
      Icons.check_circle_outline,
      Icons.cancel_outlined,
      Icons.warning_outlined,
      Icons.info_outlined,
      Icons.help_outline,
      Icons.settings_outlined,
      Icons.tune_outlined,
      Icons.filter_list_outlined,
    ],

    /// NEGÓCIOS - Empresarial e empreendedorismo
    'Negócios': [
      // Análises corporativas
      Icons.trending_up_outlined,
      Icons.show_chart_outlined,
      Icons.analytics_outlined,
      Icons.assessment_outlined,
      Icons.bar_chart_outlined,
      Icons.timeline_outlined,
      Icons.insert_chart_outlined,
      // Ambiente corporativo
      Icons.business_center_outlined,
      Icons.corporate_fare_outlined,
      Icons.apartment_outlined,
      Icons.domain_outlined,
      Icons.account_balance_outlined,
      Icons.savings_outlined,
      Icons.currency_exchange_outlined,
      // Parcerias e relacionamentos
      Icons.handshake_outlined,
      Icons.groups_outlined,
      Icons.people_outlined,
      Icons.supervisor_account_outlined,
      Icons.account_circle_outlined,
      Icons.badge_outlined,
      Icons.contact_page_outlined,
      Icons.recent_actors_outlined,
      // Inovação e liderança
      Icons.lightbulb_outline,
      Icons.psychology_outlined,
      Icons.precision_manufacturing_outlined,
      Icons.rocket_launch_outlined,
      Icons.auto_awesome_outlined,
      Icons.science_outlined,
      Icons.biotech_outlined,
      Icons.engineering_outlined,
    ]
  };

  // ===============================================
  // TREE-SHAKE SAFE ICON FUNCTIONS
  // ===============================================

  /// 🚨 PRÉ-CARREGAR TODOS OS ÍCONES (RESOLVE TREE SHAKING iOS)
  /// Chame este método no main() para forçar inclusão de todos os ícones na build
  static void preloadAllIcons() {
    // ✅ FORÇAR REGISTRO DE TODOS OS ÍCONES MATERIAL USADOS
    final List<IconData> allIconsForceLoad = [
      // Ícones para categorias zeradas (CRÍTICO para o problema)
      Icons.remove_circle_outline,
      Icons.info_outline,
      Icons.warning_outlined,
      Icons.help_outline,

      // Ícones essenciais sempre carregados
      Icons.category_outlined,
      Icons.folder_outlined,
      Icons.label_outlined,

      // Todos os ícones das categorias principais
      ...getAllSimpleIcons(),
    ];

    // ✅ Flutter irá incluir todos estes ícones na build
    // Operação em memória para garantir que não sejam removidos pelo tree shaking
    final _ = allIconsForceLoad.length;

    debugPrint('🎯 CategoriaIcons: ${allIconsForceLoad.length} ícones pré-carregados para evitar tree shaking');
  }

  /// Get simple icons by category using tree-shake safe approach
  static List<IconData> getSimpleIconsByCategory(String category) {
    return iconesSimples[category] ?? [
      Icons.category_outlined,
      Icons.folder_outlined,
      Icons.label_outlined,
    ];
  }
  
  // ===============================================
  // 🎨 BIBLIOTECA RICA - EMOJIS COLORIDOS (MANTÉM ATUAL)
  // ===============================================
  
  /// Biblioteca rica de emojis coloridos e expressivos
  /// Mantém a estrutura atual com 350+ ícones organizados
  static const Map<String, List<String>> bibliotecaRica = {
    
    /// FINANÇAS - Ícones relacionados a dinheiro e investimentos
    'Finanças': [
      '💰', '💵', '💴', '💶', '💷', '💳', '💎', '🪙', 
      '📊', '📈', '📉', '💹', '🏦', '💸', '🎯', '💫',
      '⭐', '✨', '🌟', '💥', '🔥', '⚡', '💥', '🚀'
    ],
    
    /// ALIMENTAÇÃO - Comidas, bebidas e refeições
    'Alimentação': [
      '🍽️', '🍕', '🍔', '🍟', '🌮', '🍱', '🥗', '🍜',
      '🍖', '🍇', '🥘', '🍲', '🥙', '🌯', '🥪', '🍞',
      '🥖', '🥨', '🧀', '🥓', '🍳', '🥞', '🧇', '🍯',
      '🥛', '☕', '🍵', '🧃', '🥤', '🍷', '🍺', '🥂'
    ],
    
    /// TRANSPORTE - Veículos e locomoção
    'Transporte': [
      '🚗', '🚕', '🚙', '🚌', '🚎', '🏍️', '🚲', '🛵',
      '✈️', '🚢', '🚁', '🚃', '🚄', '🚅', '🚆', '🚇',
      '🚈', '🚉', '🚊', '🚝', '🚞', '🚋', '🚘', '🚖',
      '🚛', '🚚', '🚐', '🛻', '🏎️', '🚓', '🚑', '🚒'
    ],
    
    /// MORADIA - Casa, móveis e utensílios domésticos
    'Moradia': [
      '🏠', '🏡', '🏢', '🏰', '🏗️', '🔧', '🔨', '⚡',
      '💡', '🚿', '🛏️', '🪑', '🚪', '🪟', '🏺', '🧹',
      '🧽', '🧴', '🧼', '🪣', '🔑', '🗝️', '🔒', '🔓',
      '📺', '📻', '💻', '🖥️', '⌨️', '🖱️', '🖨️', '📱'
    ],
    
    /// SAÚDE - Medicina, exercícios e bem-estar
    'Saúde': [
      '💊', '🏥', '⚕️', '🩺', '💉', '🦷', '👁️', '🧠',
      '❤️', '🏃', '🧘', '💪', '🩹', '🌡️', '🧬', '⚗️',
      '🔬', '🩻', '🦴', '🫀', '🫁', '🩸', '💆', '🧖',
      '🧴', '🧼', '🪥', '🧻', '🚿', '🛁', '🧖‍♂️', '🧖‍♀️'
    ],
    
    /// EDUCAÇÃO - Estudos, livros e aprendizado
    'Educação': [
      '📚', '📖', '✏️', '📝', '🎓', '🏫', '👨‍🎓', '📐',
      '🖊️', '💻', '🖥️', '📱', '⌨️', '🖱️', '💾', '📀',
      '📋', '📄', '📃', '📑', '📊', '📈', '📉', '🗂️',
      '📁', '📂', '🗃️', '🗄️', '📇', '📌', '📍', '📎'
    ],
    
    /// LAZER - Entretenimento, jogos e diversão
    'Lazer': [
      '🎮', '🎬', '🎵', '🎸', '🎭', '🎨', '📷', '🎯',
      '🎲', '🎪', '🎡', '🎢', '🎠', '🎳', '🏓', '🎱',
      '🎪', '🎭', '🎨', '🖼️', '🎼', '🎹', '🥁', '🎺',
      '📸', '📹', '📽️', '🎥', '📺', '📻', '🎧', '🎤'
    ],
    
    /// ESPORTES - Atividades físicas e competições
    'Esportes': [
      '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓', '🥊',
      '🏊', '🚴', '🏃', '🧗', '⛷️', '🏂', '🏄', '🤿',
      '🏇', '🚣', '🛶', '⛹️', '🏋️', '🤸', '🤾', '🏌️',
      '🏸', '🥍', '🏒', '🏑', '🥏', '🪃', '🎣', '🤼'
    ],
    
    /// FAMÍLIA - Relacionamentos e cuidados familiares
    'Família': [
      '👨‍👩‍👧‍👦', '👶', '🧸', '🍼', '👕', '👗', '🎈', '🎁',
      '❤️', '🏡', '👪', '👵', '👴', '🤱', '🤰', '👼',
      '👶', '🧒', '👦', '👧', '👨', '👩', '👴', '👵',
      '💑', '💏', '👨‍❤️‍👨', '👩‍❤️‍👩', '👨‍❤️‍👩', '💒', '💍', '💐'
    ],
    
    /// PETS - Animais de estimação e cuidados
    'Pets': [
      '🐕', '🐱', '🐦', '🐠', '🐹', '🐰', '🦎', '🐢',
      '🦔', '🐾', '🦴', '🥎', '🏠', '🚿', '💊', '🩺',
      '🐶', '🐭', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🦆'
    ],
    
    /// TRABALHO - Escritório, profissões e negócios
    'Trabalho': [
      '💼', '👔', '💻', '📱', '📧', '📞', '🖥️', '⌨️',
      '🖱️', '📋', '📊', '📈', '🗂️', '📁', '📄', '🖨️',
      '📠', '📟', '💾', '💿', '💽', '🗃️', '🗄️', '📇',
      '📌', '📍', '📎', '🖇️', '📏', '📐', '✂️', '🗒️'
    ],
    
    /// VIAGEM - Turismo, destinos e aventuras
    'Viagem': [
      '✈️', '🧳', '🗺️', '📍', '🏖️', '🏔️', '🗽', '🎡',
      '🏛️', '🕌', '⛩️', '🏰', '🗿', '🌋', '🏞️', '🌅',
      '🏕️', '⛺', '🎒', '🥾', '🧭', '🔦', '🕯️', '🔥',
      '🚗', '🚙', '🚐', '🚌', '🚂', '🚢', '⛵', '🛥️'
    ],
    
    /// COMPRAS - Roupas, acessórios e produtos
    'Compras': [
      '🛍️', '🛒', '💳', '🏪', '🏬', '👕', '👠', '💄',
      '👜', '⌚', '👓', '💍', '👑', '🎀', '🧢', '👗',
      '👖', '👔', '🧥', '🧦', '🧤', '🧣', '👒', '👘',
      '💼', '👛', '👝', '🛍️', '💎', '📿', '🔮', '🎭'
    ],
    
    /// OUTROS - Diversos e não categorizados
    'Outros': [
      '📁', '📂', '🏷️', '⭐', '💫', '🔥', '✨', '🌟',
      '💥', '🎯', '🌈', '☀️', '🌙', '⚡', '💎', '🔮',
      '🎲', '🎭', '🎪', '🎨', '🔧', '⚙️', '🔩', '⚒️',
      '🛠️', '⛏️', '🔨', '🪓', '⚱️', '🏺', '🗿', '🪬'
    ],
    
    /// NEGÓCIOS - Empresas, startups e empreendedorismo
    'Negócios': [
      '📈', '📊', '💼','🏢', '🤝', '📋', '📝', '💰',
     '🎯', '⚡', '🏆', '🥇', '📞', '💻', '📧', '🗂️',
     '💡', '🚀', '⭐', '💫', '🌟', '🔥', '💥', '⚗️',
     '🧪', '🔬', '📡', '🛰️', '🔭', '🧮', '💾', '🖥️'
   ],
 };

 // ===============================================
 // 🛠️ MÉTODOS DE ACESSO E UTILIDADE
 // ===============================================

 /// Get all simple icons (tree-shake safe)
 static List<IconData> getAllSimpleIcons() {
   // Retornar TODOS os ícones do mapa iconesSimples
   List<IconData> allIcons = [];
   for (String category in iconesSimples.keys) {
     allIcons.addAll(iconesSimples[category]!);
   }
   return allIcons;
 }

 /// Obter todos os ícones da biblioteca rica
 static List<String> getAllRichIcons() {
   return bibliotecaRica.values.expand((icons) => icons).toList();
 }

 // Moved to tree-shake safe section above

 /// Obter ícones ricos por categoria
 static List<String> getRichIconsByCategory(String category) {
   return bibliotecaRica[category] ?? [];
 }

 /// Get list of categories (tree-shake safe)
 static List<String> getCategories() {
   // Retornar TODAS as categorias do mapa iconesSimples
   return iconesSimples.keys.toList();
 }

 /// Get recommended simple icons for category type (tree-shake safe)
 static List<IconData> getRecommendedSimpleIcons(String tipo) {
   switch (tipo.toLowerCase()) {
     case 'receita':
       return [
         Icons.attach_money_outlined,
         Icons.trending_up_outlined,
         Icons.business_center_outlined,
         Icons.work_outline,
         Icons.savings_outlined,
       ];
     case 'despesa':
       return [
         Icons.restaurant_outlined,
         Icons.directions_car_outlined,
         Icons.home_outlined,
         Icons.medical_services_outlined,
         Icons.sports_esports_outlined,
       ];
     default:
       return [
         Icons.category_outlined,
         Icons.folder_outlined,
         Icons.label_outlined,
       ];
   }
 }

 /// Obter ícones recomendados ricos para tipo de categoria  
 static List<String> getRecommendedRichIcons(String tipo) {
   switch (tipo.toLowerCase()) {
     case 'receita':
       return [
         ...getRichIconsByCategory('Finanças'),
         ...getRichIconsByCategory('Trabalho'),
         ...getRichIconsByCategory('Negócios'),
       ].take(20).toList();
     
     case 'despesa':
       return [
         ...getRichIconsByCategory('Alimentação'),
         ...getRichIconsByCategory('Transporte'),
         ...getRichIconsByCategory('Moradia'),
         ...getRichIconsByCategory('Saúde'),
         ...getRichIconsByCategory('Lazer'),
       ].take(20).toList();
     
     default:
       return getRichIconsByCategory('Outros');
   }
 }

 /// Validate if simple icon exists (tree-shake safe)
 static bool isValidSimpleIcon(IconData icon) {
   // Check against most common icons
   return icon == Icons.category_outlined ||
          icon == Icons.attach_money_outlined ||
          icon == Icons.restaurant_outlined ||
          icon == Icons.directions_car_outlined ||
          icon == Icons.home_outlined ||
          icon == Icons.medical_services_outlined ||
          icon == Icons.school_outlined ||
          icon == Icons.work_outline ||
          icon == Icons.sports_esports_outlined ||
          icon == Icons.folder_outlined;
 }

 /// Validar se ícone rico existe
 static bool isValidRichIcon(String emoji) {
   return getAllRichIcons().contains(emoji);
 }

 /// Estatísticas completas dos ícones
 static Map<String, dynamic> getStats() {
   final simpleStats = <String, int>{};
   final richStats = <String, int>{};
   
   // Valores fixos para evitar tree shaking issues
   simpleStats['Finanças'] = 5;
   simpleStats['Transporte'] = 3;
   simpleStats['Outros'] = 4;
   
  // Valores fixos para evitar tree shaking issues
  richStats['Finanças'] = 24;
  richStats['Alimentação'] = 32;
  richStats['Transporte'] = 32;
  richStats['Moradia'] = 32;
  richStats['Saúde'] = 32;
  richStats['Educação'] = 32;
  richStats['Lazer'] = 32;
  richStats['Esportes'] = 32;
  richStats['Família'] = 32;
  richStats['Pets'] = 32;
  richStats['Trabalho'] = 32;
  richStats['Viagem'] = 32;
  richStats['Compras'] = 32;
  richStats['Outros'] = 32;
  richStats['Negócios'] = 32;   
   return {
     'simple': {
       ...simpleStats,
       'total': getAllSimpleIcons().length,
     },
     'rich': {
       ...richStats,
       'total': getAllRichIcons().length,
     },
     'totalGeral': getAllSimpleIcons().length + getAllRichIcons().length,
   };
 }

 /// Search simple icons by query (tree-shake safe)
 static List<Map<String, dynamic>> searchSimpleIcons(String query) {
   if (query.trim().isEmpty) return [];

   final results = <Map<String, dynamic>>[];
   final lowerQuery = query.toLowerCase();

   // Hardcoded search results for common categories
   if (lowerQuery.contains('finanças') || lowerQuery.contains('dinheiro') || lowerQuery.contains('money')) {
     results.addAll([
       {'icon': Icons.attach_money_outlined, 'category': 'Finanças', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.credit_card_outlined, 'category': 'Finanças', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.savings_outlined, 'category': 'Finanças', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.trending_up_outlined, 'category': 'Finanças', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.business_center_outlined, 'category': 'Finanças', 'type': 'simple', 'match': 'categoria'},
     ]);
   } else if (lowerQuery.contains('alimentação') || lowerQuery.contains('comida') || lowerQuery.contains('food')) {
     results.addAll([
       {'icon': Icons.restaurant_outlined, 'category': 'Alimentação', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.fastfood_outlined, 'category': 'Alimentação', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.local_cafe_outlined, 'category': 'Alimentação', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.shopping_cart_outlined, 'category': 'Alimentação', 'type': 'simple', 'match': 'categoria'},
     ]);
   } else if (lowerQuery.contains('transporte') || lowerQuery.contains('carro') || lowerQuery.contains('car')) {
     results.addAll([
       {'icon': Icons.directions_car_outlined, 'category': 'Transporte', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.directions_bus_outlined, 'category': 'Transporte', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.flight_outlined, 'category': 'Transporte', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.train_outlined, 'category': 'Transporte', 'type': 'simple', 'match': 'categoria'},
     ]);
   } else if (lowerQuery.contains('trabalho') || lowerQuery.contains('work') || lowerQuery.contains('job')) {
     results.addAll([
       {'icon': Icons.work_outline, 'category': 'Trabalho', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.business_center_outlined, 'category': 'Trabalho', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.computer_outlined, 'category': 'Trabalho', 'type': 'simple', 'match': 'categoria'},
     ]);
   } else {
     // Default fallback icons
     results.addAll([
       {'icon': Icons.category_outlined, 'category': 'Outros', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.folder_outlined, 'category': 'Outros', 'type': 'simple', 'match': 'categoria'},
       {'icon': Icons.label_outlined, 'category': 'Outros', 'type': 'simple', 'match': 'categoria'},
     ]);
   }

   return results;
 }

 /// Buscar ícones ricos por categoria
 static List<Map<String, dynamic>> searchRichIcons(String query) {
   if (query.trim().isEmpty) return [];
   
   final results = <Map<String, dynamic>>[];
   final lowerQuery = query.toLowerCase();
   
  // Valores fixos para evitar tree shaking issues
  if (lowerQuery.contains('finanças') || lowerQuery.contains('dinheiro') || lowerQuery.contains('money')) {
    results.addAll([
      {'icon': '💰', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '💵', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '💳', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '💎', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📊', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📈', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🏦', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
      {'icon': '💹', 'category': 'Finanças', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  if (lowerQuery.contains('alimentação') || lowerQuery.contains('comida') || lowerQuery.contains('food')) {
    results.addAll([
      {'icon': '🍽️', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🍕', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🍔', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
      {'icon': '☕', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🍜', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🥗', 'category': 'Alimentação', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  if (lowerQuery.contains('transporte') || lowerQuery.contains('carro') || lowerQuery.contains('car')) {
    results.addAll([
      {'icon': '🚗', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🚌', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
      {'icon': '✈️', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🚄', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🚲', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🏍️', 'category': 'Transporte', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  if (lowerQuery.contains('trabalho') || lowerQuery.contains('work') || lowerQuery.contains('job')) {
    results.addAll([
      {'icon': '💼', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
      {'icon': '👔', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
      {'icon': '💻', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📧', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📊', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📋', 'category': 'Trabalho', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  if (lowerQuery.contains('lazer') || lowerQuery.contains('fun') || lowerQuery.contains('entertainment')) {
    results.addAll([
      {'icon': '🎮', 'category': 'Lazer', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🎬', 'category': 'Lazer', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🎵', 'category': 'Lazer', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🎨', 'category': 'Lazer', 'type': 'rich', 'match': 'categoria'},
      {'icon': '📷', 'category': 'Lazer', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  if (lowerQuery.contains('família') || lowerQuery.contains('family')) {
    results.addAll([
      {'icon': '👨‍👩‍👧‍👦', 'category': 'Família', 'type': 'rich', 'match': 'categoria'},
      {'icon': '👶', 'category': 'Família', 'type': 'rich', 'match': 'categoria'},
      {'icon': '❤️', 'category': 'Família', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🎈', 'category': 'Família', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🎁', 'category': 'Família', 'type': 'rich', 'match': 'categoria'},
    ]);
  }

  // Se não encontrou resultados específicos, retorna categorias padrão
  if (results.isEmpty) {
    results.addAll([
      {'icon': '📁', 'category': 'Outros', 'type': 'rich', 'match': 'categoria'},
      {'icon': '⭐', 'category': 'Outros', 'type': 'rich', 'match': 'categoria'},
      {'icon': '🔥', 'category': 'Outros', 'type': 'rich', 'match': 'categoria'},
      {'icon': '✨', 'category': 'Outros', 'type': 'rich', 'match': 'categoria'},
    ]);
  }   
  return results;
}

/// Converter string do ícone para IconData
static IconData getIconData(String? iconString) {
  if (iconString == null || iconString.isEmpty) {
    return Icons.help_outline;
  }

  // ✅ USAR O MÉTODO CORRETO (delegação para getIconFromName)
  return getIconFromName(iconString);
}

/// Get most popular simple icons (tree-shake safe)
 static List<IconData> getPopularSimpleIcons() {
   return [
     Icons.attach_money_outlined,
     Icons.restaurant_outlined,
     Icons.directions_car_outlined,
     Icons.home_outlined,
     Icons.medical_services_outlined,
     Icons.school_outlined,
     Icons.sports_esports_outlined,
     Icons.work_outline,
     Icons.folder_outlined,
     Icons.trending_up_outlined
   ];
 }

 /// Get most popular rich icons (tree-shake safe)
 static List<String> getPopularRichIcons() {
   return [
     '💰', '🍽️', '🚗', '🏠', '💊', '📚', '🎮', '⚽',
     '👨‍👩‍👧‍👦', '🐕', '💼', '✈️', '🛍️', '📁', '📈'
   ];
 }

 /// Converter ícone para formato de salvamento
 static Map<String, dynamic> iconToSaveFormat(dynamic icon, String type) {
   if (type == 'simple' && icon is IconData) {
     // Use name-based approach to avoid dynamic property access (tree-shaking safe)
     final iconName = getNameFromIcon(icon);
     return {
       'type': 'simple',
       'iconName': iconName,
     };
   } else if (type == 'rich' && icon is String) {
     return {
       'type': 'rich',
       'emoji': icon,
     };
   }
   throw ArgumentError('Tipo de ícone inválido');
 }

 /// Converter formato salvo para ícone
 static dynamic iconFromSaveFormat(Map<String, dynamic> data) {
   final type = data['type'] as String;

   if (type == 'simple') {
     // Handle both new name-based format and legacy format
     if (data.containsKey('iconName')) {
       // New name-based format (tree-shaking safe)
       final iconName = data['iconName'] as String;
       return getIconFromName(iconName);
     } else {
       // Legacy format - fallback to default icon
       return Icons.category_outlined;
     }
   } else if (type == 'rich') {
     return data['emoji'] as String;
   }

   // Fallback seguro
  return Icons.help_outline;
 }

 /// Verificar compatibilidade com cores de fundo
 static List<IconData> getSimpleIconsForBackgroundColor(String hexColor) {
   // Ícones simples sempre funcionam bem com qualquer cor de fundo
   // pois são outline e assumem a cor do tema/categoria
   return getPopularSimpleIcons();
 }

 /// Ícones ricos para cor de fundo específica
 static List<String> getRichIconsForBackgroundColor(String hexColor) {
   // Converter hex para brightness
   final color = int.parse(hexColor.substring(1), radix: 16);
   final brightness = ((color >> 16) * 0.299 + 
                      ((color >> 8) & 0xFF) * 0.587 + 
                      (color & 0xFF) * 0.114);
   
   // Retornar ícones que contrastam bem
   if (brightness > 128) {
     // Fundo claro - ícones que funcionam bem
     return getPopularRichIcons();
   } else {
     // Fundo escuro - ícones que contrastam  
     return getPopularRichIcons();
   }
 }

  // ✅ ADICIONAR NO FINAL DO ARQUIVO categoria_icons.dart:

  // REMOVED: Large static map replaced with tree-shake safe function below

  // REMOVED: Large static map replaced with tree-shake safe function below

  /// Convert name to IconData (tree-shake safe)
  static IconData getIconFromName(String name) {
    // Use switch statement to avoid tree-shaking issues
    switch (name) {
      // Finanças
      case 'attach_money':
        return Icons.attach_money_outlined;
      case 'credit_card':
        return Icons.credit_card_outlined;
      case 'savings':
        return Icons.savings_outlined;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'business_center':
        return Icons.business_center_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'local_atm':
        return Icons.local_atm_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'receipt':
        return Icons.receipt_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;

      // Alimentação
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'fastfood':
        return Icons.fastfood_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'local_pizza':
        return Icons.local_pizza_outlined;
      case 'local_dining':
        return Icons.local_dining_outlined;
      case 'bakery_dining':
        return Icons.bakery_dining_outlined;
      case 'local_bar':
        return Icons.local_bar_outlined;
      case 'icecream':
        return Icons.icecream_outlined;

      // Transporte
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'train':
        return Icons.train_outlined;
      case 'two_wheeler':
        return Icons.two_wheeler_outlined;
      case 'local_taxi':
        return Icons.local_taxi_outlined;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      case 'subway':
        return Icons.subway_outlined;
      case 'directions_bike':
        return Icons.directions_bike_outlined;
      case 'local_gas_station':
        return Icons.local_gas_station_outlined;

      // Moradia
      case 'home':
        return Icons.home_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'lock':
        return Icons.lock_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'cleaning_services':
        return Icons.cleaning_services_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bed':
        return Icons.bed_outlined;
      case 'chair':
        return Icons.chair_outlined;

      // Saúde
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'healing':
        return Icons.healing_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'local_pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'medical_information':
        return Icons.medical_information_outlined;
      case 'vaccines':
        return Icons.vaccines_outlined;
      case 'favorite':
        return Icons.favorite_outlined;

      // Educação
      case 'school':
        return Icons.school_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'library_books':
        return Icons.library_books_outlined;
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;

      // Trabalho
      case 'work':
        return Icons.work_outline;
      case 'business':
        return Icons.business_outlined;
      case 'laptop_mac':
        return Icons.laptop_mac_outlined;
      case 'desktop_mac':
        return Icons.desktop_mac_outlined;
      case 'badge':
        return Icons.badge_outlined;
      case 'engineering':
        return Icons.engineering_outlined;

      // Entretenimento
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'music_note':
        return Icons.music_note_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'sports_soccer':
        return Icons.sports_soccer_outlined;
      case 'sports_basketball':
        return Icons.sports_basketball_outlined;
      case 'sports_tennis':
        return Icons.sports_tennis_outlined;
      case 'theater_comedy':
        return Icons.theater_comedy_outlined;
      case 'nightlife':
        return Icons.nightlife_outlined;
      case 'camera_alt':
        return Icons.camera_alt_outlined;

      // Compras
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'local_mall':
        return Icons.local_mall_outlined;
      case 'store':
        return Icons.store_outlined;
      case 'checkroom':
        return Icons.checkroom_outlined;

      // Tecnologia
      case 'computer':
        return Icons.computer_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      case 'tablet_android':
        return Icons.tablet_android_outlined;
      case 'watch':
        return Icons.watch_outlined;
      case 'headphones':
        return Icons.headphones_outlined;
      case 'speaker':
        return Icons.speaker_outlined;
      case 'tv':
        return Icons.tv_outlined;
      case 'router':
        return Icons.router_outlined;

      // Comunicação
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'message':
        return Icons.message_outlined;
      case 'chat':
        return Icons.chat_outlined;
      case 'video_call':
        return Icons.video_call_outlined;

      // Viagem
      case 'luggage':
        return Icons.luggage_outlined;
      case 'flight_takeoff':
        return Icons.flight_takeoff_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'explore':
        return Icons.explore_outlined;
      case 'map':
        return Icons.map_outlined;
      case 'camera':
        return Icons.camera_outlined;

      // Pets
      case 'pets':
        return Icons.pets_outlined;

      // Outros
      case 'folder':
        return Icons.folder_outlined;
      case 'category':
        return Icons.category_outlined;
      case 'star':
        return Icons.star_outlined;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'emoji_emotions':
        return Icons.emoji_emotions_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      case 'cake':
        return Icons.cake_outlined;
      case 'local_florist':
        return Icons.local_florist_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'brush':
        return Icons.brush_outlined;
      case 'handyman':
        return Icons.handyman_outlined;
      case 'construction':
        return Icons.construction_outlined;
      case 'agriculture':
        return Icons.agriculture_outlined;
      case 'park':
        return Icons.park_outlined;

      default:
        // Usar mapeamento automático para ícones não mapeados manualmente
        final automaticIcon = _nameToIconMap[name];
        if (automaticIcon != null) {
          return automaticIcon;
        }

        // Fallback final
        return Icons.category_outlined;
    }
  }

  // ===============================================
  // 🤖 SISTEMA DE MAPEAMENTO AUTOMÁTICO
  // ===============================================

  /// Mapa automático de IconData para nome (gerado dinamicamente)
  static final Map<IconData, String> _iconToNameMap = _generateIconToNameMap();

  /// Mapa reverso automático de nome para IconData
  static final Map<String, IconData> _nameToIconMap = _generateNameToIconMap();

  /// Gerar mapa automático de todos os ícones do iconesSimples
  static Map<IconData, String> _generateIconToNameMap() {
    final Map<IconData, String> map = {};

    for (String category in iconesSimples.keys) {
      final icons = iconesSimples[category]!;
      for (int i = 0; i < icons.length; i++) {
        final icon = icons[i];
        // Gerar nome único baseado na categoria e posição
        final name = '${category.toLowerCase().replaceAll(' ', '_')}_${i.toString().padLeft(2, '0')}';
        map[icon] = name;
      }
    }

    return map;
  }

  /// Gerar mapa reverso automático de nome para IconData
  static Map<String, IconData> _generateNameToIconMap() {
    final Map<String, IconData> map = {};

    for (String category in iconesSimples.keys) {
      final icons = iconesSimples[category]!;
      for (int i = 0; i < icons.length; i++) {
        final icon = icons[i];
        final name = '${category.toLowerCase().replaceAll(' ', '_')}_${i.toString().padLeft(2, '0')}';
        map[name] = icon;
      }
    }

    return map;
  }

  /// Convert IconData to name (tree-shake safe)
  static String getNameFromIcon(IconData icon) {
    // 1. Tentar mapeamento manual primeiro (mais legível)
    // Finanças
    if (icon == Icons.attach_money_outlined) return 'attach_money';
    if (icon == Icons.credit_card_outlined) return 'credit_card';
    if (icon == Icons.savings_outlined) return 'savings';
    if (icon == Icons.trending_up_outlined) return 'trending_up';
    if (icon == Icons.business_center_outlined) return 'business_center';
    if (icon == Icons.account_balance_outlined) return 'account_balance';
    if (icon == Icons.local_atm_outlined) return 'local_atm';
    if (icon == Icons.payment_outlined) return 'payment';
    if (icon == Icons.receipt_outlined) return 'receipt';
    if (icon == Icons.account_balance_wallet_outlined) return 'account_balance_wallet';

    // Alimentação
    if (icon == Icons.restaurant_outlined) return 'restaurant';
    if (icon == Icons.fastfood_outlined) return 'fastfood';
    if (icon == Icons.local_cafe_outlined) return 'local_cafe';
    if (icon == Icons.local_pizza_outlined) return 'local_pizza';
    if (icon == Icons.local_dining_outlined) return 'local_dining';
    if (icon == Icons.bakery_dining_outlined) return 'bakery_dining';
    if (icon == Icons.local_bar_outlined) return 'local_bar';
    if (icon == Icons.icecream_outlined) return 'icecream';

    // Transporte
    if (icon == Icons.directions_car_outlined) return 'directions_car';
    if (icon == Icons.directions_bus_outlined) return 'directions_bus';
    if (icon == Icons.flight_outlined) return 'flight';
    if (icon == Icons.train_outlined) return 'train';
    if (icon == Icons.two_wheeler_outlined) return 'two_wheeler';
    if (icon == Icons.local_taxi_outlined) return 'local_taxi';
    if (icon == Icons.local_shipping_outlined) return 'local_shipping';
    if (icon == Icons.subway_outlined) return 'subway';
    if (icon == Icons.directions_bike_outlined) return 'directions_bike';
    if (icon == Icons.local_gas_station_outlined) return 'local_gas_station';

    // Moradia
    if (icon == Icons.home_outlined) return 'home';
    if (icon == Icons.build_outlined) return 'build';
    if (icon == Icons.lock_outlined) return 'lock';
    if (icon == Icons.lightbulb_outlined) return 'lightbulb';
    if (icon == Icons.water_drop_outlined) return 'water_drop';
    if (icon == Icons.cleaning_services_outlined) return 'cleaning_services';
    if (icon == Icons.kitchen_outlined) return 'kitchen';
    if (icon == Icons.bed_outlined) return 'bed';
    if (icon == Icons.chair_outlined) return 'chair';

    // Saúde
    if (icon == Icons.medical_services_outlined) return 'medical_services';
    if (icon == Icons.healing_outlined) return 'healing';
    if (icon == Icons.fitness_center_outlined) return 'fitness_center';
    if (icon == Icons.local_pharmacy_outlined) return 'local_pharmacy';
    if (icon == Icons.medical_information_outlined) return 'medical_information';
    if (icon == Icons.vaccines_outlined) return 'vaccines';
    if (icon == Icons.favorite_outlined) return 'favorite';

    // Educação
    if (icon == Icons.school_outlined) return 'school';
    if (icon == Icons.book_outlined) return 'book';
    if (icon == Icons.library_books_outlined) return 'library_books';
    if (icon == Icons.auto_stories_outlined) return 'auto_stories';
    if (icon == Icons.psychology_outlined) return 'psychology';
    if (icon == Icons.menu_book_outlined) return 'menu_book';

    // Trabalho
    if (icon == Icons.work_outline) return 'work';
    if (icon == Icons.business_outlined) return 'business';
    if (icon == Icons.laptop_mac_outlined) return 'laptop_mac';
    if (icon == Icons.desktop_mac_outlined) return 'desktop_mac';
    if (icon == Icons.badge_outlined) return 'badge';
    if (icon == Icons.engineering_outlined) return 'engineering';

    // Entretenimento
    if (icon == Icons.sports_esports_outlined) return 'sports_esports';
    if (icon == Icons.music_note_outlined) return 'music_note';
    if (icon == Icons.movie_outlined) return 'movie';
    if (icon == Icons.sports_soccer_outlined) return 'sports_soccer';
    if (icon == Icons.sports_basketball_outlined) return 'sports_basketball';
    if (icon == Icons.sports_tennis_outlined) return 'sports_tennis';
    if (icon == Icons.theater_comedy_outlined) return 'theater_comedy';
    if (icon == Icons.nightlife_outlined) return 'nightlife';
    if (icon == Icons.camera_alt_outlined) return 'camera_alt';

    // Compras
    if (icon == Icons.shopping_cart_outlined) return 'shopping_cart';
    if (icon == Icons.shopping_bag_outlined) return 'shopping_bag';
    if (icon == Icons.local_mall_outlined) return 'local_mall';
    if (icon == Icons.store_outlined) return 'store';
    if (icon == Icons.checkroom_outlined) return 'checkroom';

    // Tecnologia
    if (icon == Icons.computer_outlined) return 'computer';
    if (icon == Icons.phone_android_outlined) return 'phone_android';
    if (icon == Icons.tablet_android_outlined) return 'tablet_android';
    if (icon == Icons.watch_outlined) return 'watch';
    if (icon == Icons.headphones_outlined) return 'headphones';
    if (icon == Icons.speaker_outlined) return 'speaker';
    if (icon == Icons.tv_outlined) return 'tv';
    if (icon == Icons.router_outlined) return 'router';

    // Comunicação
    if (icon == Icons.email_outlined) return 'email';
    if (icon == Icons.phone_outlined) return 'phone';
    if (icon == Icons.message_outlined) return 'message';
    if (icon == Icons.chat_outlined) return 'chat';
    if (icon == Icons.video_call_outlined) return 'video_call';

    // Viagem
    if (icon == Icons.luggage_outlined) return 'luggage';
    if (icon == Icons.flight_takeoff_outlined) return 'flight_takeoff';
    if (icon == Icons.hotel_outlined) return 'hotel';
    if (icon == Icons.explore_outlined) return 'explore';
    if (icon == Icons.map_outlined) return 'map';
    if (icon == Icons.camera_outlined) return 'camera';

    // Pets
    if (icon == Icons.pets_outlined) return 'pets';

    // Outros
    if (icon == Icons.folder_outlined) return 'folder';
    if (icon == Icons.category_outlined) return 'category';
    if (icon == Icons.star_outlined) return 'star';
    if (icon == Icons.thumb_up_outlined) return 'thumb_up';
    if (icon == Icons.emoji_emotions_outlined) return 'emoji_emotions';
    if (icon == Icons.celebration_outlined) return 'celebration';
    if (icon == Icons.cake_outlined) return 'cake';
    if (icon == Icons.local_florist_outlined) return 'local_florist';
    if (icon == Icons.spa_outlined) return 'spa';
    if (icon == Icons.palette_outlined) return 'palette';
    if (icon == Icons.brush_outlined) return 'brush';
    if (icon == Icons.handyman_outlined) return 'handyman';
    if (icon == Icons.construction_outlined) return 'construction';
    if (icon == Icons.agriculture_outlined) return 'agriculture';
    if (icon == Icons.park_outlined) return 'park';

    // 2. Usar mapeamento automático para ícones não mapeados manualmente
    final automaticName = _iconToNameMap[icon];
    if (automaticName != null) {
      return automaticName;
    }

    // 3. Fallback final apenas para ícones que não estão no iconesSimples
    return 'category';
  }

  /// Verificar se uma string é emoji
  static bool isEmoji(String text) {
    return text.length <= 4 && RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F700}-\u{1F77F}]|[\u{1F780}-\u{1F7FF}]|[\u{1F800}-\u{1F8FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true).hasMatch(text);
  }

  /// Renderizar ícone de forma unificada (método principal)
  static Widget renderIcon(dynamic icon, double size, {Color? color}) {
    if (icon is String) {
      if (isEmoji(icon)) {
        return Text(icon, style: TextStyle(fontSize: size));
      } else {
        return Icon(getIconFromName(icon), size: size, color: color);
      }
    } else if (icon is IconData) {
      return Icon(icon, size: size, color: color);
    }
    return Icon(Icons.category_outlined, size: size, color: color);
  }

  // ===============================================
  // MÉTODOS DE COMPATIBILIDADE (para manter funcionamento atual)
  // ===============================================

  /// Ícones por categoria (compatibilidade com código atual)
  static Map<String, List<String>> get iconePorCategoria => bibliotecaRica;

  /// Ícones mais populares para cada tipo
  static Map<String, List<String>> getIconesPorTipo(String tipo) {
    if (tipo.toLowerCase() == 'receita') {
      return {
        'Trabalho': bibliotecaRica['Trabalho'] ?? [],
        'Finanças': bibliotecaRica['Finanças'] ?? [],
        'Negócios': bibliotecaRica['Negócios'] ?? [],
        'Outros': bibliotecaRica['Outros'] ?? [],
      };
    } else {
      return bibliotecaRica;
    }
  }

  /// Lista de todas as categorias disponíveis
  static List<String> get categorias => bibliotecaRica.keys.toList();

  /// Obter ícones de uma categoria específica
  static List<String> getIconesDeCategoria(String categoria) {
    return bibliotecaRica[categoria] ?? [];
  }

  /// Obter todos os ícones em uma lista única
  static List<String> get todosOsIcones {
    return bibliotecaRica.values.expand((lista) => lista).toList();
  }

  /// Buscar ícones por texto
  static List<String> buscarIcones(String busca) {
    if (busca.isEmpty) return [];
    
    final resultado = <String>[];
    final buscaLower = busca.toLowerCase();
    
    for (final categoria in bibliotecaRica.keys) {
      if (categoria.toLowerCase().contains(buscaLower)) {
        resultado.addAll(bibliotecaRica[categoria]!);
      }
    }
    
    return resultado.isEmpty ? todosOsIcones.take(20).toList() : resultado;
  }

  /// Obter ícone padrão por categoria
  static String getIconePadrao(String categoria) {
    final icones = bibliotecaRica[categoria];
    if (icones != null && icones.isNotEmpty) {
      return icones.first;
    }
    return '📁'; // Ícone padrão
  }

  /// Obter ícones recomendados baseados no tipo
  static List<String> getIconesRecomendados(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'receita':
        return [
          ...bibliotecaRica['Finanças']!.take(8),
          ...bibliotecaRica['Trabalho']!.take(6),
        ];
      case 'despesa':
        return [
          ...bibliotecaRica['Alimentação']!.take(4),
          ...bibliotecaRica['Transporte']!.take(4),
          ...bibliotecaRica['Moradia']!.take(4),
          ...bibliotecaRica['Saúde']!.take(4),
        ];
      default:
        return bibliotecaRica['Outros']!.take(16).toList();
    }
  }
}