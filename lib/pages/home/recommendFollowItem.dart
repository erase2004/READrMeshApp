import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readr/blocs/home/home_bloc.dart';
import 'package:readr/helpers/router/router.dart';
import 'package:readr/models/member.dart';
import 'package:readr/pages/shared/profilePhotoWidget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecommendFollowItem extends StatefulWidget {
  final Member recommendMember;
  final Member member;
  const RecommendFollowItem(this.recommendMember, this.member);

  @override
  _RecommendFollowItemState createState() => _RecommendFollowItemState();
}

class _RecommendFollowItemState extends State<RecommendFollowItem> {
  int _followerCount = 0;
  String _followerNickName = "";

  @override
  void initState() {
    super.initState();
    _followerCount = widget.recommendMember.followerCount ?? 0;
    if (widget.recommendMember.follower != null &&
        widget.recommendMember.follower!.isNotEmpty) {
      _followerNickName = widget.recommendMember.follower![0].nickname;
    }
  }

  @override
  Widget build(BuildContext context) {
    String contentText = '為你推薦';
    if (_followerCount == 1) {
      contentText = '$_followerNickName的追蹤對象';
    } else if (_followerCount > 1) {
      contentText = '$_followerNickName 及其他 ${_followerCount - 1} 人的追蹤對象';
    }

    return GestureDetector(
      onTap: () {
        AutoRouter.of(context).push(PersonalFileRoute(
            viewMember: widget.recommendMember, currentMember: widget.member));
      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color.fromRGBO(0, 9, 40, 0.1), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePhotoWidget(widget.recommendMember, 32),
              const SizedBox(height: 12),
              Text(
                widget.recommendMember.nickname,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: Text(
                  contentText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _followButton(widget.recommendMember),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _followButton(Member targetMember) {
    bool isFollowed = false;
    if (widget.member.following != null) {
      isFollowed = widget.member.following!
          .any((member) => member.memberId == targetMember.memberId);
    }
    return OutlinedButton(
      onPressed: () async {
        // check whether is login
        if (FirebaseAuth.instance.currentUser != null) {
          context.read<HomeBloc>().add(
              UpdateFollowingMember(targetMember, widget.member, isFollowed));
        } else {
          // if user is not login
          Fluttertoast.showToast(
            msg: "請先登入",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.grey[600],
            textColor: Colors.white,
            fontSize: 16.0,
          );
          AutoRouter.of(context).push(const LoginRoute());
        }
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black87, width: 1),
        backgroundColor: isFollowed ? Colors.black87 : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        isFollowed ? '追蹤中' : '追蹤',
        maxLines: 1,
        style: TextStyle(
          fontSize: 16,
          color: isFollowed ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
