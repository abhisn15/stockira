import 'package:flutter/material.dart';
import '../models/store.dart';

class StoreItemWidget extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;
  final bool showDistance;
  final bool showStatus;

  const StoreItemWidget({
    super.key,
    required this.store,
    this.onTap,
    this.showDistance = true,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with store name and status
                Row(
                  children: [
                    // Store icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getIconBackgroundColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStoreIcon(),
                        color: _getIconColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Store name and code
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status badge
                    if (showStatus) _buildStatusBadge(),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Store details
                Row(
                  children: [
                    // Account type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAccountColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        store.account.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getAccountColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Distance
                    if (showDistance) ...[
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.distanceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        store.displayAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Distribution info
                if (store.distribution != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.business,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          store.distribution!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (store.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 12,
              color: Colors.green[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Approved',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (store.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending,
              size: 12,
              color: Colors.orange[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 12,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Unknown',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getBorderColor() {
    if (store.isApproved) {
      return Colors.green[200]!;
    } else if (store.isPending) {
      return Colors.orange[200]!;
    } else {
      return Colors.grey[200]!;
    }
  }

  Color _getIconBackgroundColor() {
    if (store.isApproved) {
      return Colors.green[50]!;
    } else if (store.isPending) {
      return Colors.orange[50]!;
    } else {
      return Colors.grey[50]!;
    }
  }

  Color _getIconColor() {
    if (store.isApproved) {
      return Colors.green[600]!;
    } else if (store.isPending) {
      return Colors.orange[600]!;
    } else {
      return Colors.grey[600]!;
    }
  }

  IconData _getStoreIcon() {
    if (store.isApproved) {
      return Icons.store;
    } else if (store.isPending) {
      return Icons.store_outlined;
    } else {
      return Icons.store_mall_directory_outlined;
    }
  }

  Color _getAccountColor() {
    switch (store.account.name.toUpperCase()) {
      case 'ALFAMART':
        return Colors.blue[600]!;
      case 'ALFAMIDI':
        return Colors.purple[600]!;
      case 'INDOMARET':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class StoreListWidget extends StatelessWidget {
  final List<Store> stores;
  final Function(Store)? onStoreTap;
  final bool showDistance;
  final bool showStatus;
  final String? emptyMessage;
  final Widget? emptyWidget;

  const StoreListWidget({
    super.key,
    required this.stores,
    this.onStoreTap,
    this.showDistance = true,
    this.showStatus = true,
    this.emptyMessage,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return emptyWidget ?? _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return StoreItemWidget(
          store: store,
          onTap: onStoreTap != null ? () => onStoreTap!(store) : null,
          showDistance: showDistance,
          showStatus: showStatus,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'Tidak ada store ditemukan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah radius pencarian atau lokasi Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
