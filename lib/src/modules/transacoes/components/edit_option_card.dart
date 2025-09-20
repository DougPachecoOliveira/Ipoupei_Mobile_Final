import 'package:flutter/material.dart';
import '../../shared/theme/app_colors.dart';

/// Card reutilizável para opções de edição
/// Usado na página principal de edição para organizar as ações disponíveis
class EditOptionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final VoidCallback? onTap;
  final bool habilitado;
  final String? mensagemDesabilitado;

  const EditOptionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    this.onTap,
    this.habilitado = true,
    this.mensagemDesabilitado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: habilitado 
            ? cor.withOpacity(0.2) 
            : AppColors.cinzaMedio.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: habilitado ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: habilitado 
                      ? cor.withOpacity(0.1) 
                      : AppColors.cinzaMedio.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icone,
                    color: habilitado ? cor : AppColors.cinzaMedio,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: habilitado ? AppColors.cinzaEscuro : AppColors.cinzaMedio,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habilitado ? subtitulo : mensagemDesabilitado ?? subtitulo,
                        style: TextStyle(
                          fontSize: 14,
                          color: habilitado ? AppColors.cinzaTexto : AppColors.cinzaMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicador de navegação
                if (habilitado)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: cor,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card especial para opções destrutivas (excluir, etc.)
class DestructiveOptionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final VoidCallback? onTap;
  final bool habilitado;
  final String? mensagemDesabilitado;

  const DestructiveOptionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    this.onTap,
    this.habilitado = true,
    this.mensagemDesabilitado,
  });

  @override
  Widget build(BuildContext context) {
    return EditOptionCard(
      titulo: titulo,
      subtitulo: subtitulo,
      icone: icone,
      cor: AppColors.vermelhoErro,
      onTap: habilitado ? onTap : null,
      habilitado: habilitado,
      mensagemDesabilitado: mensagemDesabilitado,
    );
  }
}

/// Card especial para ações de confirmação (efetivar, salvar, etc.)
class ConfirmationOptionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final VoidCallback? onTap;
  final bool habilitado;

  const ConfirmationOptionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return EditOptionCard(
      titulo: titulo,
      subtitulo: subtitulo,
      icone: icone,
      cor: AppColors.verdeSucesso,
      onTap: habilitado ? onTap : null,
      habilitado: habilitado,
    );
  }
}

/// Card especial para ações informativas (duplicar, visualizar, etc.)
class InfoOptionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final VoidCallback? onTap;

  const InfoOptionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EditOptionCard(
      titulo: titulo,
      subtitulo: subtitulo,
      icone: icone,
      cor: AppColors.azul,
      onTap: onTap,
    );
  }
}