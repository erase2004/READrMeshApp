part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class InitialHomeScreen extends HomeEvent {
  @override
  String toString() => 'InitialHomeScreen';
}

class ReloadHomeScreen extends HomeEvent {
  @override
  String toString() => 'ReloadHomeScreen';
}

class LoadMoreFollowingPicked extends HomeEvent {
  final List<String> alreadyFetchIds;

  const LoadMoreFollowingPicked(this.alreadyFetchIds);

  @override
  String toString() => 'LoadMoreFollowingPicked';
}

class LoadMoreLatestNews extends HomeEvent {
  final DateTime lastPublishTime;

  const LoadMoreLatestNews(this.lastPublishTime);

  @override
  String toString() => 'LoadMoreLatestNews';
}
