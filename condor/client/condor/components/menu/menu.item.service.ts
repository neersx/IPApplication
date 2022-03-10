class MenuItemService {
   static $inject = ['http'];

   constructor(private http) {
   }

   getDueDatePresentation(queryKey: string) {
      return this.http
         .get(
            'api/search/case/dueDatePresentation/' +
            encodeURI(queryKey.toString()),
            {
               params: {
                  params: JSON.stringify(queryKey)
               }
            }
         )
   }

   getDueDateSavedSearch(queryKey: string) {
      return this.http
         .get('api/search/case/casesearch/builder/' + queryKey)
   }
}

angular.module('inprotech.components.menu')
   .service('menuItemService', MenuItemService);
