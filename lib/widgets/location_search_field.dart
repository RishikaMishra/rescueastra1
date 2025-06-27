import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'dart:async';

class LocationSearchField extends StatefulWidget {
  final String apiKey;
  final TextEditingController controller;
  final Function(LatLng position, String address) onLocationSelected;
  final String hint;

  const LocationSearchField({
    super.key,
    required this.apiKey,
    required this.controller,
    required this.onLocationSelected,
    this.hint = 'Search locations',
  });

  @override
  _LocationSearchFieldState createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  late GoogleMapsPlaces _places;
  List<Prediction> _predictions = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _debounce?.cancel();
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (widget.controller.text.isNotEmpty) {
        _searchPlaces(widget.controller.text);
      } else {
        setState(() {
          _predictions = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _places.autocomplete(
        input,
        language: 'en',
        components: [Component(Component.country, 'in')], // India
        types: ['geocode', 'address', 'establishment', 'regions', 'cities'],
      );

      if (response.isOkay) {
        setState(() {
          _predictions = response.predictions;
          _isSearching = false;
        });
      } else {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectPlace(Prediction prediction) async {
    try {
      final details = await _places.getDetailsByPlaceId(prediction.placeId!);
      if (details.isOkay) {
        final lat = details.result.geometry!.location.lat;
        final lng = details.result.geometry!.location.lng;
        final address = details.result.formattedAddress ?? prediction.description ?? '';

        widget.controller.text = address;
        widget.onLocationSelected(LatLng(lat, lng), address);

        setState(() {
          _predictions = [];
        });
        _focusNode.unfocus();
      }
    } catch (e) {
      // Handle error silently or show user-friendly message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(Icons.location_on, color: Colors.deepPurple),
            suffixIcon: _isSearching
                ? Container(
                    width: 20,
                    height: 20,
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {
                            _predictions = [];
                          });
                        },
                      )
                    : Icon(Icons.search, color: Colors.deepPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurple, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        if (_predictions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _predictions.length > 5 ? 5 : _predictions.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.location_on, color: Colors.deepPurple),
                  title: Text(
                    _predictions[index].description ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlace(_predictions[index]),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
