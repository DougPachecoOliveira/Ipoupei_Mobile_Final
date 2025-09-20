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

 /// Obter todos os ícones simples
 static List<IconData> getAllSimpleIcons() {
   return iconesSimples.values.expand((icons) => icons).toList();
 }

 /// Obter todos os ícones da biblioteca rica
 static List<String> getAllRichIcons() {
   return bibliotecaRica.values.expand((icons) => icons).toList();
 }

 /// Obter ícones simples por categoria
 static List<IconData> getSimpleIconsByCategory(String category) {
   return iconesSimples[category] ?? [];
 }

 /// Obter ícones ricos por categoria
 static List<String> getRichIconsByCategory(String category) {
   return bibliotecaRica[category] ?? [];
 }

 /// Obter lista de categorias
 static List<String> getCategories() {
   return iconesSimples.keys.toList();
 }

 /// Obter ícones recomendados simples para tipo de categoria
 static List<IconData> getRecommendedSimpleIcons(String tipo) {
   switch (tipo.toLowerCase()) {
     case 'receita':
       return [
         ...getSimpleIconsByCategory('Finanças'),
         ...getSimpleIconsByCategory('Trabalho'),
         ...getSimpleIconsByCategory('Negócios'),
       ].take(20).toList();
     
     case 'despesa':
       return [
         ...getSimpleIconsByCategory('Alimentação'),
         ...getSimpleIconsByCategory('Transporte'),
         ...getSimpleIconsByCategory('Moradia'),
         ...getSimpleIconsByCategory('Saúde'),
         ...getSimpleIconsByCategory('Lazer'),
       ].take(20).toList();
     
     default:
       return getSimpleIconsByCategory('Outros');
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

 /// Validar se ícone simples existe
 static bool isValidSimpleIcon(IconData icon) {
   return getAllSimpleIcons().contains(icon);
 }

 /// Validar se ícone rico existe
 static bool isValidRichIcon(String emoji) {
   return getAllRichIcons().contains(emoji);
 }

 /// Estatísticas completas dos ícones
 static Map<String, dynamic> getStats() {
   final simpleStats = <String, int>{};
   final richStats = <String, int>{};
   
   for (final entry in iconesSimples.entries) {
     simpleStats[entry.key] = entry.value.length;
   }
   
   for (final entry in bibliotecaRica.entries) {
     richStats[entry.key] = entry.value.length;
   }
   
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

 /// Buscar ícones simples por categoria
 static List<Map<String, dynamic>> searchSimpleIcons(String query) {
   if (query.trim().isEmpty) return [];
   
   final results = <Map<String, dynamic>>[];
   final lowerQuery = query.toLowerCase();
   
   for (final entry in iconesSimples.entries) {
     final categoryName = entry.key.toLowerCase();
     
     if (categoryName.contains(lowerQuery)) {
       for (final icon in entry.value) {
         results.add({
           'icon': icon,
           'category': entry.key,
           'type': 'simple',
           'match': 'categoria'
         });
       }
     }
   }
   
   return results;
 }

 /// Buscar ícones ricos por categoria
 static List<Map<String, dynamic>> searchRichIcons(String query) {
   if (query.trim().isEmpty) return [];
   
   final results = <Map<String, dynamic>>[];
   final lowerQuery = query.toLowerCase();
   
   for (final entry in bibliotecaRica.entries) {
     final categoryName = entry.key.toLowerCase();
     
     if (categoryName.contains(lowerQuery)) {
       for (final icon in entry.value) {
         results.add({
           'icon': icon,
           'category': entry.key,
           'type': 'rich',
           'match': 'categoria'
         });
       }
     }
   }
   
   return results;
 }

 /// Ícones mais populares simples
 static List<IconData> getPopularSimpleIcons() {
   return [
     Icons.attach_money_outlined,
     Icons.restaurant_outlined,
     Icons.directions_car_outlined,
     Icons.home_outlined,
     Icons.medical_services_outlined,
     Icons.school_outlined,
     Icons.sports_esports_outlined,
     Icons.sports_soccer_outlined,
     Icons.family_restroom_outlined,
     Icons.pets_outlined,
     Icons.work_outline,
     Icons.flight_outlined,
     Icons.shopping_cart_outlined,
     Icons.folder_outlined,
     Icons.trending_up_outlined
   ];
 }

 /// Ícones mais populares ricos
 static List<String> getPopularRichIcons() {
   return [
     '💰', '🍽️', '🚗', '🏠', '💊', '📚', '🎮', '⚽',
     '👨‍👩‍👧‍👦', '🐕', '💼', '✈️', '🛍️', '📁', '📈'
   ];
 }

 /// Converter ícone para formato de salvamento
 static Map<String, dynamic> iconToSaveFormat(dynamic icon, String type) {
   if (type == 'simple' && icon is IconData) {
     return {
       'type': 'simple',
       'codePoint': icon.codePoint,
       'fontFamily': icon.fontFamily,
       'fontPackage': icon.fontPackage,
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
     return IconData(
       data['codePoint'] as int,
       fontFamily: data['fontFamily'] as String?,
       fontPackage: data['fontPackage'] as String?,
     );
   } else if (type == 'rich') {
     return data['emoji'] as String;
   }
   
   throw ArgumentError('Formato de ícone salvo inválido');
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

  /// Mapeamento completo de nomes para IconData (compatibilidade total)
  static const Map<String, IconData> nameToIconData = {
    // ===============================================
    // FINANÇAS - Ícones financeiros
    // ===============================================
    'attach_money': Icons.attach_money_outlined,
    'euro': Icons.euro_outlined,
    'credit_card': Icons.credit_card_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'account_balance': Icons.account_balance_outlined,
    'savings': Icons.savings_outlined,
    'monetization_on': Icons.monetization_on_outlined,
    'payment': Icons.payment_outlined,
    'trending_up': Icons.trending_up_outlined,
    'trending_down': Icons.trending_down_outlined,
    'show_chart': Icons.show_chart_outlined,
    'analytics': Icons.analytics_outlined,
    'assessment': Icons.assessment_outlined,
    'bar_chart': Icons.bar_chart_outlined,
    'timeline': Icons.timeline_outlined,
    'business_center': Icons.business_center_outlined,
    'work': Icons.work_outline,
    'corporate_fare': Icons.corporate_fare_outlined,
    'apartment': Icons.apartment_outlined,
    'star': Icons.star_outline,
    'diamond': Icons.diamond_outlined,
    'emoji_events': Icons.emoji_events_outlined,
    'military_tech': Icons.military_tech_outlined,

    // ===============================================
    // ALIMENTAÇÃO - Comida e bebida
    // ===============================================
    'restaurant': Icons.restaurant_outlined,
    'fastfood': Icons.fastfood_outlined,
    'dinner_dining': Icons.dinner_dining_outlined,
    'lunch_dining': Icons.lunch_dining_outlined,
    'breakfast_dining': Icons.breakfast_dining_outlined,
    'local_dining': Icons.local_dining_outlined,
    'room_service': Icons.room_service_outlined,
    'takeout_dining': Icons.takeout_dining_outlined,
    'local_cafe': Icons.local_cafe_outlined,
    'local_bar': Icons.local_bar_outlined,
    'wine_bar': Icons.wine_bar_outlined,
    'coffee': Icons.coffee_outlined,
    'emoji_food_beverage': Icons.emoji_food_beverage_outlined,
    'local_drink': Icons.local_drink_outlined,
    'liquor': Icons.liquor_outlined,
    'sports_bar': Icons.sports_bar_outlined,
    'local_grocery_store': Icons.local_grocery_store_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'store': Icons.store_outlined,
    'storefront': Icons.storefront_outlined,
    'kitchen': Icons.kitchen_outlined,
    'microwave': Icons.microwave_outlined,

    // ===============================================
    // TRANSPORTE - Veículos e locomoção
    // ===============================================
    'directions_car': Icons.directions_car_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'flight': Icons.flight_outlined,
    'train': Icons.train_outlined,
    'subway': Icons.subway_outlined,
    'directions_bike': Icons.directions_bike_outlined,
    'motorcycle': Icons.motorcycle_outlined,
    'electric_scooter': Icons.electric_scooter_outlined,
    'local_taxi': Icons.local_taxi_outlined,
    'directions_boat': Icons.directions_boat_outlined,
    'sailing': Icons.sailing_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'local_parking': Icons.local_parking_outlined,
    'garage': Icons.garage_outlined,
    'car_repair': Icons.car_repair_outlined,
    'traffic': Icons.traffic_outlined,

    // ===============================================
    // MORADIA - Casa e utensílios
    // ===============================================
    'home': Icons.home_outlined,
    'house': Icons.house_outlined,
    'cottage': Icons.cottage_outlined,
    'villa': Icons.villa_outlined,
    'build': Icons.build_outlined,
    'construction': Icons.construction_outlined,
    'electrical_services': Icons.electrical_services_outlined,
    'plumbing': Icons.plumbing_outlined,
    'chair': Icons.chair_outlined,
    'bed': Icons.bed_outlined,
    'table_restaurant': Icons.table_restaurant_outlined,
    'lightbulb': Icons.lightbulb_outline,
    'lock': Icons.lock_outlined,
    'security': Icons.security_outlined,
    'vpn_key': Icons.vpn_key_outlined,
    'key': Icons.key_outlined,

    // ===============================================
    // SAÚDE - Medicina e bem-estar
    // ===============================================
    'local_hospital': Icons.local_hospital_outlined,
    'medical_services': Icons.medical_services_outlined,
    'medication': Icons.medication_outlined,
    'vaccines': Icons.vaccines_outlined,
    'healing': Icons.healing_outlined,
    'health_and_safety': Icons.health_and_safety_outlined,
    'monitor_heart': Icons.monitor_heart_outlined,
    'psychology': Icons.psychology_outlined,
    'sentiment_satisfied': Icons.sentiment_satisfied_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'spa': Icons.spa_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'directions_run': Icons.directions_run_outlined,
    'directions_walk': Icons.directions_walk_outlined,
    'pool': Icons.pool_outlined,
    'sports_gymnastics': Icons.sports_gymnastics_outlined,
    'accessible': Icons.accessible_outlined,
    'pregnant_woman': Icons.pregnant_woman_outlined,
    'child_care': Icons.child_care_outlined,
    'baby_changing_station': Icons.baby_changing_station_outlined,
    'sanitizer': Icons.sanitizer_outlined,
    'thermostat': Icons.thermostat_outlined,

    // ===============================================
    // EDUCAÇÃO - Estudos e aprendizado
    // ===============================================
    'school': Icons.school_outlined,
    'auto_stories': Icons.auto_stories_outlined,
    'menu_book': Icons.menu_book_outlined,
    'library_books': Icons.library_books_outlined,
    'book': Icons.book_outlined,
    'bookmark': Icons.bookmark_outline,
    'class': Icons.class_outlined,
    'groups': Icons.groups_outlined,
    'edit': Icons.edit_outlined,
    'create': Icons.create_outlined,
    'draw': Icons.draw_outlined,
    'format_paint': Icons.format_paint_outlined,
    'highlight': Icons.highlight_outlined,
    'text_fields': Icons.text_fields_outlined,
    'title': Icons.title_outlined,
    'article': Icons.article_outlined,
    'computer': Icons.computer_outlined,
    'laptop': Icons.laptop_outlined,
    'tablet': Icons.tablet_outlined,
    'phone_android': Icons.phone_android_outlined,
    'cast_for_education': Icons.cast_for_education_outlined,
    'screen_share': Icons.screen_share_outlined,
    'slideshow': Icons.slideshow_outlined,

    // ===============================================
    // LAZER - Entretenimento e diversão
    // ===============================================
    'sports_esports': Icons.sports_esports_outlined,
    'casino': Icons.casino_outlined,
    'toys': Icons.toys_outlined,
    'extension': Icons.extension_outlined,
    'games': Icons.games_outlined,
    'smart_toy': Icons.smart_toy_outlined,
    'videogame_asset': Icons.videogame_asset_outlined,
    'sports': Icons.sports_outlined,
    'music_note': Icons.music_note_outlined,
    'library_music': Icons.library_music_outlined,
    'album': Icons.album_outlined,
    'audiotrack': Icons.audiotrack_outlined,
    'headphones': Icons.headphones_outlined,
    'speaker': Icons.speaker_outlined,
    'radio': Icons.radio_outlined,
    'mic': Icons.mic_outlined,
    'movie': Icons.movie_outlined,
    'theaters': Icons.theaters_outlined,
    'live_tv': Icons.live_tv_outlined,
    'video_library': Icons.video_library_outlined,
    'camera_alt': Icons.camera_alt_outlined,
    'photo_camera': Icons.photo_camera_outlined,
    'videocam': Icons.videocam_outlined,
    'collections': Icons.collections_outlined,

    // ===============================================
    // ESPORTES - Atividades físicas
    // ===============================================
    'sports_soccer': Icons.sports_soccer_outlined,
    'sports_basketball': Icons.sports_basketball_outlined,
    'sports_football': Icons.sports_football_outlined,
    'sports_baseball': Icons.sports_baseball_outlined,
    'sports_tennis': Icons.sports_tennis_outlined,
    'sports_volleyball': Icons.sports_volleyball_outlined,
    'sports_golf': Icons.sports_golf_outlined,
    'sports_hockey': Icons.sports_hockey_outlined,
    'hiking': Icons.hiking_outlined,
    'snowboarding': Icons.snowboarding_outlined,
    'surfing': Icons.surfing_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,
    'shield': Icons.shield_outlined,
    'flag': Icons.flag_outlined,
    'timer': Icons.timer_outlined,

    // ===============================================
    // FAMÍLIA - Relacionamentos e cuidados
    // ===============================================
    'family_restroom': Icons.family_restroom_outlined,
    'escalator_warning': Icons.escalator_warning_outlined,
    'elderly': Icons.elderly_outlined,
    'person': Icons.person_outlined,
    'people': Icons.people_outlined,
    'weekend': Icons.weekend_outlined,
    'dining': Icons.dining_outlined,
    'celebration': Icons.celebration_outlined,
    'cake': Icons.cake_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'redeem': Icons.redeem_outlined,
    'volunteer_activism': Icons.volunteer_activism_outlined,
    'favorite': Icons.favorite_outline,
    'support': Icons.support_outlined,
    'emoji_emotions': Icons.emoji_emotions_outlined,

    // ===============================================
    // PETS - Animais de estimação
    // ===============================================
    'pets': Icons.pets_outlined,
    'cruelty_free': Icons.cruelty_free_outlined,
    'emergency': Icons.emergency_outlined,
    'water_drop': Icons.water_drop_outlined,
    'opacity': Icons.opacity_outlined,
    'nature': Icons.nature_outlined,
    'park': Icons.park_outlined,

    // ===============================================
    // TRABALHO - Atividades profissionais
    // ===============================================
    'meeting_room': Icons.meeting_room_outlined,
    'domain': Icons.domain_outlined,
    'badge': Icons.badge_outlined,
    'contact_page': Icons.contact_page_outlined,
    'recent_actors': Icons.recent_actors_outlined,
    'supervisor_account': Icons.supervisor_account_outlined,
    'account_circle': Icons.account_circle_outlined,
    'engineering': Icons.engineering_outlined,
    'science': Icons.science_outlined,
    'biotech': Icons.biotech_outlined,
    'precision_manufacturing': Icons.precision_manufacturing_outlined,
    'rocket_launch': Icons.rocket_launch_outlined,
    'auto_awesome': Icons.auto_awesome_outlined,
    'description': Icons.description_outlined,
    'assignment': Icons.assignment_outlined,
    'folder': Icons.folder_outlined,
    'folder_open': Icons.folder_open_outlined,
    'insert_drive_file': Icons.insert_drive_file_outlined,
    'picture_as_pdf': Icons.picture_as_pdf_outlined,
    'text_snippet': Icons.text_snippet_outlined,
    'email': Icons.email_outlined,
    'message': Icons.message_outlined,
    'chat': Icons.chat_outlined,
    'video_call': Icons.video_call_outlined,
    'call': Icons.call_outlined,
    'contacts': Icons.contacts_outlined,

    // ===============================================
    // VIAGEM - Turismo e aventuras
    // ===============================================
    'local_airport': Icons.local_airport_outlined,
    'connecting_airports': Icons.connecting_airports_outlined,
    'flight_takeoff': Icons.flight_takeoff_outlined,
    'flight_land': Icons.flight_land_outlined,
    'hotel': Icons.hotel_outlined,
    'rv_hookup': Icons.rv_hookup_outlined,
    'map': Icons.map_outlined,
    'explore': Icons.explore_outlined,
    'tour': Icons.tour_outlined,
    'landscape': Icons.landscape_outlined,
    'place': Icons.place_outlined,
    'luggage': Icons.luggage_outlined,
    'backpack': Icons.backpack_outlined,
    'card_travel': Icons.card_travel_outlined,
    'travel_explore': Icons.travel_explore_outlined,
    'public': Icons.public_outlined,
    'language': Icons.language_outlined,

    // ===============================================
    // COMPRAS - Produtos e serviços
    // ===============================================
    'shopping_bag': Icons.shopping_bag_outlined,
    'shopping_basket': Icons.shopping_basket_outlined,
    'local_mall': Icons.local_mall_outlined,
    'add_shopping_cart': Icons.add_shopping_cart_outlined,
    'remove_shopping_cart': Icons.remove_shopping_cart_outlined,
    'local_atm': Icons.local_atm_outlined,
    'point_of_sale': Icons.point_of_sale_outlined,
    'receipt': Icons.receipt_outlined,
    'checkroom': Icons.checkroom_outlined,
    'dry_cleaning': Icons.dry_cleaning_outlined,
    'local_laundry_service': Icons.local_laundry_service_outlined,
    'woman': Icons.woman_outlined,
    'man': Icons.man_outlined,
    'face': Icons.face_outlined,
    'brush': Icons.brush_outlined,
    'delivery_dining': Icons.delivery_dining_outlined,
    'local_shipping': Icons.local_shipping_outlined,
    'inventory': Icons.inventory_outlined,
    'qr_code': Icons.qr_code_outlined,

    // ===============================================
    // OUTROS - Diversos e não categorizados
    // ===============================================
    'create_new_folder': Icons.create_new_folder_outlined,
    'topic': Icons.topic_outlined,
    'label': Icons.label_outlined,
    'push_pin': Icons.push_pin_outlined,
    'grade': Icons.grade_outlined,
    'bolt': Icons.bolt_outlined,
    'flash_on': Icons.flash_on_outlined,
    'wb_sunny': Icons.wb_sunny_outlined,
    'arrow_upward': Icons.arrow_upward_outlined,
    'arrow_downward': Icons.arrow_downward_outlined,
    'arrow_forward': Icons.arrow_forward_outlined,
    'arrow_back': Icons.arrow_back_outlined,
    'refresh': Icons.refresh_outlined,
    'sync': Icons.sync_outlined,
    'swap_horiz': Icons.swap_horiz_outlined,
    'compare_arrows': Icons.compare_arrows_outlined,
    'check_circle': Icons.check_circle_outline,
    'cancel': Icons.cancel_outlined,
    'warning': Icons.warning_outlined,
    'info': Icons.info_outlined,
    'help': Icons.help_outline,
    'settings': Icons.settings_outlined,
    'tune': Icons.tune_outlined,
    'filter_list': Icons.filter_list_outlined,

    // ===============================================
    // NEGÓCIOS - Empresarial e empreendedorismo
    // ===============================================
    'insert_chart': Icons.insert_chart_outlined,
    'currency_exchange': Icons.currency_exchange_outlined,
    'handshake': Icons.handshake_outlined,

    // ===============================================
    // FALLBACK - Ícone padrão
    // ===============================================
    'category': Icons.category_outlined,
  };

  /// Mapeamento reverso IconData → nome (para converter ao salvar)
  static Map<IconData, String> get iconDataToName => {
    // Finanças
    Icons.attach_money_outlined: 'attach_money',
    Icons.euro_outlined: 'euro',
    Icons.credit_card_outlined: 'credit_card',
    Icons.account_balance_wallet_outlined: 'account_balance_wallet',
    Icons.account_balance_outlined: 'account_balance',
    Icons.savings_outlined: 'savings',
    Icons.monetization_on_outlined: 'monetization_on',
    Icons.payment_outlined: 'payment',
    Icons.trending_up_outlined: 'trending_up',
    Icons.trending_down_outlined: 'trending_down',
    Icons.show_chart_outlined: 'show_chart',
    Icons.analytics_outlined: 'analytics',
    Icons.assessment_outlined: 'assessment',
    Icons.bar_chart_outlined: 'bar_chart',
    Icons.timeline_outlined: 'timeline',
    Icons.business_center_outlined: 'business_center',
    Icons.work_outline: 'work',
    Icons.corporate_fare_outlined: 'corporate_fare',
    Icons.apartment_outlined: 'apartment',
    Icons.star_outline: 'star',
    Icons.diamond_outlined: 'diamond',
    Icons.emoji_events_outlined: 'emoji_events',
    Icons.military_tech_outlined: 'military_tech',

    // Alimentação
    Icons.restaurant_outlined: 'restaurant',
    Icons.fastfood_outlined: 'fastfood',
    Icons.dinner_dining_outlined: 'dinner_dining',
    Icons.lunch_dining_outlined: 'lunch_dining',
    Icons.breakfast_dining_outlined: 'breakfast_dining',
    Icons.local_dining_outlined: 'local_dining',
    Icons.room_service_outlined: 'room_service',
    Icons.takeout_dining_outlined: 'takeout_dining',
    Icons.local_cafe_outlined: 'local_cafe',
    Icons.local_bar_outlined: 'local_bar',
    Icons.wine_bar_outlined: 'wine_bar',
    Icons.coffee_outlined: 'coffee',
    Icons.emoji_food_beverage_outlined: 'emoji_food_beverage',
    Icons.local_drink_outlined: 'local_drink',
    Icons.liquor_outlined: 'liquor',
    Icons.sports_bar_outlined: 'sports_bar',
    Icons.local_grocery_store_outlined: 'local_grocery_store',
    Icons.shopping_cart_outlined: 'shopping_cart',
    Icons.store_outlined: 'store',
    Icons.storefront_outlined: 'storefront',
    Icons.kitchen_outlined: 'kitchen',
    Icons.microwave_outlined: 'microwave',

    // Transporte
    Icons.directions_car_outlined: 'directions_car',
    Icons.directions_bus_outlined: 'directions_bus',
    Icons.flight_outlined: 'flight',
    Icons.train_outlined: 'train',
    Icons.subway_outlined: 'subway',
    Icons.directions_bike_outlined: 'directions_bike',
    Icons.motorcycle_outlined: 'motorcycle',
    Icons.electric_scooter_outlined: 'electric_scooter',
    Icons.local_taxi_outlined: 'local_taxi',
    Icons.directions_boat_outlined: 'directions_boat',
    Icons.sailing_outlined: 'sailing',
    Icons.local_gas_station_outlined: 'local_gas_station',
    Icons.local_parking_outlined: 'local_parking',
    Icons.garage_outlined: 'garage',
    Icons.car_repair_outlined: 'car_repair',
    Icons.traffic_outlined: 'traffic',

    // Moradia
    Icons.home_outlined: 'home',
    Icons.house_outlined: 'house',
    Icons.cottage_outlined: 'cottage',
    Icons.villa_outlined: 'villa',
    Icons.build_outlined: 'build',
    Icons.construction_outlined: 'construction',
    Icons.electrical_services_outlined: 'electrical_services',
    Icons.plumbing_outlined: 'plumbing',
    Icons.chair_outlined: 'chair',
    Icons.bed_outlined: 'bed',
    Icons.table_restaurant_outlined: 'table_restaurant',
    Icons.lightbulb_outline: 'lightbulb',
    Icons.lock_outlined: 'lock',
    Icons.security_outlined: 'security',
    Icons.vpn_key_outlined: 'vpn_key',
    Icons.key_outlined: 'key',

    // Saúde
    Icons.local_hospital_outlined: 'local_hospital',
    Icons.medical_services_outlined: 'medical_services',
    Icons.medication_outlined: 'medication',
    Icons.vaccines_outlined: 'vaccines',
    Icons.healing_outlined: 'healing',
    Icons.health_and_safety_outlined: 'health_and_safety',
    Icons.monitor_heart_outlined: 'monitor_heart',
    Icons.psychology_outlined: 'psychology',
    Icons.sentiment_satisfied_outlined: 'sentiment_satisfied',
    Icons.fitness_center_outlined: 'fitness_center',
    Icons.spa_outlined: 'spa',
    Icons.self_improvement_outlined: 'self_improvement',
    Icons.directions_run_outlined: 'directions_run',
    Icons.directions_walk_outlined: 'directions_walk',
    Icons.pool_outlined: 'pool',
    Icons.sports_gymnastics_outlined: 'sports_gymnastics',
    Icons.accessible_outlined: 'accessible',
    Icons.pregnant_woman_outlined: 'pregnant_woman',
    Icons.child_care_outlined: 'child_care',
    Icons.baby_changing_station_outlined: 'baby_changing_station',
    Icons.sanitizer_outlined: 'sanitizer',
    Icons.thermostat_outlined: 'thermostat',

    // Educação
    Icons.school_outlined: 'school',
    Icons.auto_stories_outlined: 'auto_stories',
    Icons.menu_book_outlined: 'menu_book',
    Icons.library_books_outlined: 'library_books',
    Icons.book_outlined: 'book',
    Icons.bookmark_outline: 'bookmark',
    Icons.class_outlined: 'class',
    Icons.groups_outlined: 'groups',
    Icons.edit_outlined: 'edit',
    Icons.create_outlined: 'create',
    Icons.draw_outlined: 'draw',
    Icons.format_paint_outlined: 'format_paint',
    Icons.highlight_outlined: 'highlight',
    Icons.text_fields_outlined: 'text_fields',
    Icons.title_outlined: 'title',
    Icons.article_outlined: 'article',
    Icons.computer_outlined: 'computer',
    Icons.laptop_outlined: 'laptop',
    Icons.tablet_outlined: 'tablet',
    Icons.phone_android_outlined: 'phone_android',
    Icons.cast_for_education_outlined: 'cast_for_education',
    Icons.screen_share_outlined: 'screen_share',
    Icons.slideshow_outlined: 'slideshow',

    // Lazer
    Icons.sports_esports_outlined: 'sports_esports',
    Icons.casino_outlined: 'casino',
    Icons.toys_outlined: 'toys',
    Icons.extension_outlined: 'extension',
    Icons.games_outlined: 'games',
    Icons.smart_toy_outlined: 'smart_toy',
    Icons.videogame_asset_outlined: 'videogame_asset',
    Icons.sports_outlined: 'sports',
    Icons.music_note_outlined: 'music_note',
    Icons.library_music_outlined: 'library_music',
    Icons.album_outlined: 'album',
    Icons.audiotrack_outlined: 'audiotrack',
    Icons.headphones_outlined: 'headphones',
    Icons.speaker_outlined: 'speaker',
    Icons.radio_outlined: 'radio',
    Icons.mic_outlined: 'mic',
    Icons.movie_outlined: 'movie',
    Icons.theaters_outlined: 'theaters',
    Icons.live_tv_outlined: 'live_tv',
    Icons.video_library_outlined: 'video_library',
    Icons.camera_alt_outlined: 'camera_alt',
    Icons.photo_camera_outlined: 'photo_camera',
    Icons.videocam_outlined: 'videocam',
    Icons.collections_outlined: 'collections',

    // Fallback
    Icons.category_outlined: 'category',
  };

  /// Converter nome para IconData
  static IconData getIconFromName(String name) {
    // Se for formato icon_XXXX (codePoint em hex), converte de volta
    if (name.startsWith('icon_')) {
      try {
        final hexString = name.substring(5); // Remove 'icon_'
        final codePoint = int.parse(hexString, radix: 16);
        return IconData(codePoint, fontFamily: 'MaterialIcons');
      } catch (e) {
        // Se falhar na conversão, usa fallback
        return Icons.category_outlined;
      }
    }
    
    // Busca normal no mapa
    return nameToIconData[name] ?? Icons.category_outlined;
  }

  /// Converter IconData para nome
  static String getNameFromIcon(IconData icon) {
    return iconDataToName[icon] ?? 'category';
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