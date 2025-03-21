import 'package:flutter/material.dart';

class UserDropdown extends StatefulWidget {
  final List<String> users;
  final String? selectedUser;
  final ValueChanged<String?> onUserSelected;

  const UserDropdown({
    Key? key,
    required this.users,
    this.selectedUser,
    required this.onUserSelected,
  }) : super(key: key);

  @override
  _UserDropdownState createState() => _UserDropdownState();
}

class _UserDropdownState extends State<UserDropdown> {
  String? _selectedUser;
  TextEditingController _controller = TextEditingController();
  List<String> _filteredUsers = [];
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.selectedUser;
    _filteredUsers = widget.users;
    _controller.text = _selectedUser ?? "";
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = widget.users
          .where((user) => user.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _isDropdownVisible = _filteredUsers.isNotEmpty;
    });
  }

  void _selectUser(String user) {
    setState(() {
      _selectedUser = user;
      _controller.text = _selectedUser!;
      _isDropdownVisible = false; // Hide the dropdown list
    });
    widget.onUserSelected(_selectedUser);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _filteredUsers = widget.users; // Show all users when clicked
              _isDropdownVisible = true;
            });
          },
          child: TextFormField(
            controller: _controller,
            onChanged: _filterUsers,
            onTap: () {
              setState(() {
                _filteredUsers = widget.users; // Ensure all users are shown on tap
                _isDropdownVisible = true;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: "Type to search...",
              suffixIcon: _isDropdownVisible
                  ? IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isDropdownVisible = false;
                  });
                },
              )
                  : null,
            ),
          ),
        ),
        SizedBox(height: 8),
        
        if (_isDropdownVisible)
          Container(
            constraints: BoxConstraints(
              maxHeight: _filteredUsers.length * 50.0 > 200 ? 200 : _filteredUsers.length * 50.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredUsers[index]),
                  onTap: () => _selectUser(_filteredUsers[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}
