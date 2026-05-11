import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(latlng.LatLng position, String address) onLocationSelected;
  final String hint;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
    this.hint = 'Search locations',
  });

  @override
  _LocationSearchFieldState createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _predictions = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
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
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input)}&format=json&addressdetails=1&limit=5&countrycodes=in');
      final response = await http.get(url, headers: {'User-Agent': 'RescueAstra/1.0'});
      if (response.statusCode == 200) {
        final List results = List.from(jsonDecode(response.body));
        setState(() {
          _predictions = results.map((e) => {
            'displayName': e['display_name'],
            'lat': double.tryParse(e['lat'] ?? '0') ?? 0.0,
            'lon': double.tryParse(e['lon'] ?? '0') ?? 0.0,
          }).toList();
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

  void _selectPlace(Map<String, dynamic> prediction) {
    final lat = prediction['lat'] as double;
    final lon = prediction['lon'] as double;
    final address = prediction['displayName'] as String;
    widget.controller.text = address;
    widget.onLocationSelected(latlng.LatLng(lat, lon), address);
    setState(() {
      _predictions = [];
    });
    _focusNode.unfocus();
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
                    _predictions[index]['displayName'] as String,
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
