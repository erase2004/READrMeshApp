import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:readr/blocs/comment/comment_bloc.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/helpers/userHelper.dart';
import 'package:readr/models/comment.dart';
import 'package:readr/pages/errorPage.dart';
import 'package:readr/pages/shared/comment/commentInputBox.dart';
import 'package:readr/pages/shared/comment/commentItem.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CommentBottomSheetWidget extends StatefulWidget {
  final BuildContext context;
  final Comment clickComment;
  final String storyId;
  final ValueChanged<String> onTextChanged;
  final String? oldContent;

  const CommentBottomSheetWidget({
    required this.context,
    required this.clickComment,
    required this.storyId,
    required this.onTextChanged,
    this.oldContent,
  });

  @override
  _CommentBottomSheetWidgetState createState() =>
      _CommentBottomSheetWidgetState();
}

class _CommentBottomSheetWidgetState extends State<CommentBottomSheetWidget> {
  List<Comment> _allComments = [];
  late Comment _myNewComment;
  bool _isSending = false;
  bool _hasMyNewComment = false;
  late final TextEditingController _textController;
  final ItemScrollController _controller = ItemScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchComment();
    _textController = TextEditingController(text: widget.oldContent);
  }

  _fetchComment() {
    context.read<CommentBloc>().add(FetchComments(widget.storyId));
  }

  _createComment(String content) {
    if (!_isSending) {
      context.read<CommentBloc>().add(AddComment(
            storyId: widget.storyId,
            content: content,
            commentTransparency: CommentTransparency.public,
          ));
      _myNewComment = Comment(
        id: 'sending',
        member: UserHelper.instance.currentUser,
        content: content,
        state: "public",
        publishDate: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        color: Colors.white,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                color: Colors.white,
                child: const Icon(
                  Icons.expand_more_outlined,
                  color: readrBlack30,
                  size: 32,
                ),
              ),
            ),
            Flexible(
              child: BlocConsumer<CommentBloc, CommentState>(
                listener: (context, state) {
                  if (state is AddCommentFailed) {
                    Fluttertoast.showToast(
                      msg: "留言失敗，請稍後再試一次",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  }
                },
                builder: (context, state) {
                  if (state is CommentError) {
                    return SizedBox(
                      height: 500,
                      child: ErrorPage(
                        error: state.error,
                        onPressed: () => _fetchComment(),
                        hideAppbar: true,
                      ),
                    );
                  }

                  if (state is CommentLoaded) {
                    _allComments = state.comments;
                    int index = _allComments.indexWhere(
                        (comment) => comment.id == widget.clickComment.id);
                    Timer.periodic(const Duration(microseconds: 1), (timer) {
                      if (_controller.isAttached) {
                        _controller.scrollTo(
                            index: index,
                            duration: const Duration(
                              microseconds: 1,
                            ));
                        timer.cancel();
                      }
                    });
                    _isSending = false;
                    _isInitialized = true;

                    return _buildContent();
                  }

                  if (state is AddCommentFailed) {
                    if (_allComments[0].id == 'sending') {
                      _allComments.removeAt(0);
                    }
                    _isSending = false;
                    return _buildContent();
                  }

                  if (state is AddCommentSuccess && _isInitialized) {
                    _allComments = state.comments;

                    // find new comment position
                    int index = _allComments.indexWhere((element) {
                      if (element.content == _myNewComment.content &&
                          element.member.memberId ==
                              _myNewComment.member.memberId) {
                        return true;
                      }
                      return false;
                    });

                    //if not found, just return new comments
                    if (index == -1) {
                      return _buildContent();
                    }

                    // if it's not the first, move to first
                    if (index != 0) {
                      _myNewComment = _allComments.elementAt(index);
                      _allComments.removeAt(index);
                      _allComments.insert(0, _myNewComment);
                    }
                    _hasMyNewComment = true;
                    if (_isSending) {
                      Timer(const Duration(seconds: 5, milliseconds: 5),
                          () => _hasMyNewComment = false);
                    }

                    _isSending = false;
                    _textController.clear();

                    return _buildContent();
                  }

                  if (state is CommentAdding) {
                    if (!_isSending) {
                      _allComments.insert(0, _myNewComment);
                    }

                    _isSending = true;
                    return _buildContent();
                  }

                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: ScrollablePositionedList.separated(
                  itemCount: _allComments.length,
                  itemScrollController: _controller,
                  padding: const EdgeInsets.all(0),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return CommentItem(
                      key: ValueKey(_allComments[index].id),
                      comment: _allComments[index],
                      isSending: (_isSending && index == 0),
                      isMyNewComment: _hasMyNewComment && index == 0,
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                    color: readrBlack10,
                    indent: 20,
                    endIndent: 20,
                    thickness: 0.5,
                    height: 0.5,
                  ),
                ),
              ),
            ),
            const Divider(
              color: readrBlack10,
              thickness: 0.5,
              height: 0.5,
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: CommentInputBox(
                isSending: _isSending,
                onPressed: (text) {
                  _createComment(text);
                  _controller.scrollTo(
                      index: 0, duration: const Duration(milliseconds: 500));
                },
                onTextChanged: widget.onTextChanged,
                textController: _textController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
