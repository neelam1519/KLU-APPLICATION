import 'dart:ffi';

class StudentLeave {
  final String leaveid;
  final String parentsMobileNumber;
  final String studentMobileNumber;
  final String reason;
  final String fileLink;
  final String startdate;
  final String enddate;

  StudentLeave({
    required this.leaveid,
    required this.parentsMobileNumber,
    required this.studentMobileNumber,
    required this.reason,
    required this.fileLink,
    required this.startdate,
    required this.enddate
  });
}

class UserDetails{
  final String regNo;
  final String branch;
  final String fullname;
  final String hostel;
  final String hostelroomno;
  final String mobilenumber;
  final String section;
  final String year;
  final String email;
  final String stream;

  UserDetails(this.regNo, this.branch, this.fullname, this.hostel,
      this.hostelroomno, this.mobilenumber, this.section, this.year, this.email,this.stream);

}

class LeaveCardViewData{
  final String id;
  final String startdate;
  final String returndate;
  final String verified;

  LeaveCardViewData(this.id,this.startdate, this.returndate, this.verified);
}

class TotalLeaveData{
  final String id;
  final String regNo;
  final String branch;
  final String fullname;
  final String hostel;
  final String hostelroomno;
  final String section;
  final String year;
  final String email;
  final String stream;
  final String mobilenumber;
  final String parentmobilenumber;
  final String startdate;
  final String returndate;
  final String verified;
  final bool faapproval;
  final bool yearcoordinatorapproval;
  final bool hostelwardenapproval;
  final String reason;
  final String createddate;
  final bool yearcoordinatordeclined;
  final bool hostelwardendeclined;
  final bool fadeclined;
  final String staffid;
  final Map<String,String> mapdate;

  TotalLeaveData(
      this.id, this.regNo, this.fullname, this.startdate, this.returndate, this.branch, this.year, this.section, this.stream, this.email,
      this.mobilenumber, this.parentmobilenumber, this.hostel, this.hostelroomno, this.verified, this.faapproval, this.yearcoordinatorapproval,
      this.hostelwardenapproval, this.reason, this.createddate, this.yearcoordinatordeclined, this.hostelwardendeclined, this.fadeclined,
      this.staffid, this.mapdate);
}