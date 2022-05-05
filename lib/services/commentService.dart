import 'dart:convert';
import 'package:get/get.dart';
import 'package:readr/getxServices/userService.dart';
import 'package:readr/helpers/apiBaseHelper.dart';
import 'package:readr/helpers/dataConstants.dart';
import 'package:readr/getxServices/environmentService.dart';

import 'package:readr/models/comment.dart';
import 'package:readr/models/graphqlBody.dart';

abstract class CommentRepos {
  Future<List<Comment>?> createComment({
    required String storyId,
    required String content,
    required CommentTransparency state,
  });
  Future<bool> deleteComment(String commentId);
  Future<List<Comment>?> fetchCommentsByStoryId(String storyId);
  Future<int?> addLike({
    required String commentId,
  });
  Future<int?> removeLike({
    required String commentId,
  });
  Future<bool> editComment(Comment newComment);
}

class CommentService implements CommentRepos {
  final ApiBaseHelper _helper = ApiBaseHelper();
  final String api = Get.find<EnvironmentService>().config.readrMeshApi;

  Future<Map<String, String>> _getHeaders({bool needAuth = true}) async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
    };
    if (needAuth) {
      // TODO: Change back to firebase token when verify firebase token is finished
      String token = await _fetchCMSUserToken();
      //String token = await FirebaseAuth.instance.currentUser!.getIdToken();
      headers.addAll({"Authorization": "Bearer $token"});
    }

    return headers;
  }

  // Get READr CMS User token for authorization
  // TODO: Delete when verify firebase token is finished
  Future<String> _fetchCMSUserToken() async {
    String mutation = """
    mutation(
	    \$email: String!,
	    \$password: String!
    ){
	    authenticateUserWithPassword(
		    email: \$email
		    password: \$password
      ){
        ... on UserAuthenticationWithPasswordSuccess{
        	sessionToken
      	}
        ... on UserAuthenticationWithPasswordFailure{
          message
      	}
      }
    }
    """;

    Map<String, String> variables = {
      "email": Get.find<EnvironmentService>().config.appHelperEmail,
      "password": Get.find<EnvironmentService>().config.appHelperPassword,
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    final jsonResponse = await _helper.postByUrl(
        api, jsonEncode(graphqlBody.toJson()),
        headers: {"Content-Type": "application/json"});

    String token =
        jsonResponse['data']['authenticateUserWithPassword']['sessionToken'];

    return token;
  }

  @override
  Future<List<Comment>?> createComment({
    required String storyId,
    required String content,
    required CommentTransparency state,
  }) async {
    String mutation = """
      mutation(
        \$myId: ID
        \$storyId: ID
        \$content: String
        \$published_date: DateTime
        \$state: String
      ){
        createComment(
          data:{
            member:{
              connect:{
                id: \$myId
              }
            }
            story:{
              connect:{
                id: \$storyId
              }
            }
            content: \$content
            published_date: \$published_date
            is_active: true
            state: \$state
          }
        ){
          story{
            comment(
              where:{
                is_active:{
                  equals: true
                }
                state:{
                  equals: "public"
                }
              }
              orderBy:{
                published_date: desc
              }
            ){
              id
              member{
                id
                nickname
                email
                avatar
              }
              content
              state
              published_date
              likeCount
              is_edited
              isLiked:likeCount(
                where:{
                  is_active:{
                    equals: true
                  }
                  id:{
                    equals: \$myId
                  }
                }
              )
            }
          }
        }
      }
    """;

    Map<String, dynamic> variables = {
      "myId": Get.find<UserService>().currentUser.memberId,
      "storyId": storyId,
      "content": content,
      "published_date": DateTime.now().toUtc().toIso8601String(),
      "state": state.toString().split('.').last,
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(),
      );
      if (jsonResponse.containsKey('errors')) {
        return null;
      }

      List<Comment> allComments = [];
      for (var item in jsonResponse['data']['createComment']['story']
          ['comment']) {
        allComments.add(Comment.fromJson(item));
      }

      return allComments;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    String mutation = """
      mutation(
        \$commentId: ID
      ){
        updateComment(
          where:{
            id: \$commentId
          }
          data:{
            is_active: false
          }
        ){
          id
        }
      }
      """;

    Map<String, String> variables = {"commentId": commentId};

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(),
      );

      return !jsonResponse.containsKey('errors');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Comment>?> fetchCommentsByStoryId(String storyId) async {
    String query = """
      query(
        \$storyId: ID
        \$myId: ID
      ){
        comments(
          orderBy:{
            published_date: desc
          }
          where:{
            story:{
              id:{
                equals: \$storyId
              }
            }
            is_active:{
              equals: true
            }
            state:{
              equals: "public"
            }
            member:{
              is_active:{
                equals: true
              }
            }
          }
        ){
          id
          member{
            id
            nickname
            email
            avatar
          }
          content
          state
          published_date
          likeCount
          is_edited
          isLiked:likeCount(
            where:{
              is_active:{
                equals: true
              }
              id:{
                equals: \$myId
              }
            }
          )
        }
      }
      """;

    Map<String, String> variables = {
      "storyId": storyId,
      "myId": Get.find<UserService>().currentUser.memberId,
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: query,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(needAuth: false),
      );

      if (jsonResponse.containsKey('errors')) {
        return null;
      }

      List<Comment> allComments = [];
      for (var item in jsonResponse['data']['comments']) {
        allComments.add(Comment.fromJson(item));
      }

      return allComments;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int?> addLike({
    required String commentId,
  }) async {
    String mutation = """
    mutation(
      \$commentId: ID
      \$memberId: ID
    ){
      updateComment(
        where:{
          id: \$commentId
        }
        data:{
          like:{
            connect:{
              id: \$memberId
            }
          }
        }
      ){
        likeCount
      }
    }
    """;

    Map<String, dynamic> variables = {
      "commentId": commentId,
      "memberId": Get.find<UserService>().currentUser.memberId,
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(),
      );
      if (jsonResponse.containsKey('errors')) {
        return null;
      }

      return jsonResponse['data']['updateComment']['likeCount'];
    } catch (e) {
      return null;
    }
  }

  @override
  Future<int?> removeLike({
    required String commentId,
  }) async {
    String mutation = """
    mutation(
      \$commentId: ID
      \$memberId: ID
    ){
      updateComment(
        where:{
          id: \$commentId
        }
        data:{
          like:{
            disconnect:{
              id: \$memberId
            }
          }
        }
      ){
        likeCount
      }
    }
    """;

    Map<String, dynamic> variables = {
      "commentId": commentId,
      "memberId": Get.find<UserService>().currentUser.memberId,
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(),
      );
      if (jsonResponse.containsKey('errors')) {
        return null;
      }

      return jsonResponse['data']['updateComment']['likeCount'];
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> editComment(Comment newComment) async {
    const String mutation = """
    mutation(
      \$commentId: ID
      \$newContent: String
    ){
      updateComment(
        where:{
          id: \$commentId
        }
        data:{
          is_edited: true,
          content: \$newContent
        }
      ){
        id
      }
    }
    """;

    Map<String, String> variables = {
      "commentId": newComment.id,
      "newContent": newComment.content
    };

    GraphqlBody graphqlBody = GraphqlBody(
      operationName: null,
      query: mutation,
      variables: variables,
    );

    try {
      final jsonResponse = await _helper.postByUrl(
        api,
        jsonEncode(graphqlBody.toJson()),
        headers: await _getHeaders(),
      );

      return !jsonResponse.containsKey('errors');
    } catch (e) {
      return false;
    }
  }
}
