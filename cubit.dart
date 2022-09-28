import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_udemy/layout/shop_app/categories/categories_screen.dart';
import 'package:flutter_udemy/layout/shop_app/cubit/states.dart';
import 'package:flutter_udemy/layout/shop_app/favourites/favourites_screen.dart';
import 'package:flutter_udemy/layout/shop_app/products/products_screen.dart';
import 'package:flutter_udemy/layout/shop_app/settings/settings_screen.dart';
import 'package:flutter_udemy/models/shop_app/categories_model.dart';
import 'package:flutter_udemy/models/shop_app/change_favorites_model.dart';
import 'package:flutter_udemy/models/shop_app/favorites_model.dart';
import 'package:flutter_udemy/models/shop_app/home_model.dart';
import 'package:flutter_udemy/models/shop_app/login_model.dart';
import 'package:flutter_udemy/shared/components/constants.dart';
import 'package:flutter_udemy/shared/network/remote/dio_helper.dart';
import 'package:flutter_udemy/shared/network/remote/end_point.dart';

class ShopCubit extends Cubit<ShopStates>
{
  ShopCubit() : super(ShopInitialState());

  static ShopCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;

  List<Widget> bottomScreens =
  [
    ProductsScreen(),
    CategoriesScreen(),
    FavouritesScreen(),
    SettingsScreen(),
  ];

  void changeBottom(int index)
  {
    currentIndex = index;
    emit(ShopChangeBottomNavState());
  }

  HomeModel? homeModel;

  Map<int, bool> favorites = {};

  void getHomeData()
  {
    emit(ShopLoadingHomeDataState());

    DioHelper.getData(
      url: HOME,
      token: token,
    ).then((value)
    {
      homeModel = HomeModel.fromJson(value.data);
      // print(homeModel!.data.banners[0].image);
      // print(homeModel!.status);

      homeModel!.data.products.forEach((element)
      {
        favorites.addAll({
          element.id : element.inFavorite,
        });
      });

      print(favorites.toString());

      emit(ShopSuccessHomeDataState());
    }).catchError((error){
      print(error.toString());
      emit(ShopErrorHomeDataState());
    });
  }

  CategoriesModel? categoriesModel;

  Future<void> getCategories() async
  {
    await DioHelper.getData(
      url: GET_CATEGORIES,
    ).then((value)
    {
      categoriesModel = CategoriesModel.fromJson(value.data);
      emit(ShopSuccessCategoriesState());
    }).catchError((error){
      print(error.toString());
      emit(ShopErrorCategoriesState());
    });
  }

  ChangeFavoritesModel? changeFavoritesModel;

  void changeFavorites(int productId)
  {
    favorites[productId] = !favorites[productId]!;
    emit(ShopSuccessFavoritesState());

    DioHelper.postData(
        url: FAVORITES,
        data:
        {
          'product_id' : productId,
        },
        token: token,
    ).then((value)
    {
      changeFavoritesModel = ChangeFavoritesModel.fromJson(value.data);
      print(value.data);

      if(changeFavoritesModel!.status == false)
        {
          favorites[productId] = !favorites[productId]!;
        }
      else
        {
          getFavorites();
        }

      emit(ShopSuccessChangeFavoritesState(changeFavoritesModel!));
    }).catchError((error)
    {
      favorites[productId] = !favorites[productId]!;
      emit(ShopErrorChangeFavoritesState());
    });
  }

  FavoritesModel? favoritesModel;

  Future<void> getFavorites() async
  {
    emit(ShopLoadingGetFavoritesState());

    await DioHelper.getData(
      url: FAVORITES,
      token: token,
    ).then((value)
    {
      favoritesModel = FavoritesModel.fromJson(value.data);
      emit(ShopSuccessGetFavoritesState());
    }).catchError((error){
      print(error.toString());
      emit(ShopErrorGetFavoritesState());
    });
  }

  ShopLoginModel? userModel;

  Future<void> getUserData() async
  {
    emit(ShopLoadingUserDataState());

    await DioHelper.getData(
      url: PROFILE,
      token: token,
    ).then((value)
    {
      userModel = ShopLoginModel.fromJson(value.data);
      emit(ShopSuccessUserDataState(userModel!));
    }).catchError((error){
      print(error.toString());
      emit(ShopErrorUserDataState());
    });
  }

  void updateUserData({
    required String name,
    required String phone,
    required String email,
  }){
    emit(ShopLoadingUpdateUserDataState());
    DioHelper.putData(
        url: UPDATE_PROFILE,
        token: token,
        data: {
          'name':name,
          'phone':phone,
          'email':email
        }).then((value) {
      userModel=ShopLoginModel.fromJson(value.data);
      print(userModel!.data!.name);
      emit(ShopSuccessUpdateUserDataState(userModel!));
    }).
    catchError((error)
    {
      emit(ShopErrorUpdateUserDataState());
      // print(error.toString());
    });
  }

}