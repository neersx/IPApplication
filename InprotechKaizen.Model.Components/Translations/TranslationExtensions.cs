using System;
using System.Linq.Expressions;

namespace InprotechKaizen.Model.Components.Translations
{
    public static class TranslationExtensions
    {
        public static string Translate<TEntity>(this ITranslation translation, TEntity entity, Expression<Func<TEntity, string>> propertySelector)
        {
            var propertyName = Utilities.ResolvePropertyName(propertySelector);

            return translation.Translate(entity, propertyName);
        }
    }
}