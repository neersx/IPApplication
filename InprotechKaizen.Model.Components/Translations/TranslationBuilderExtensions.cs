using System;
using System.Collections.Generic;
using System.Linq.Expressions;

namespace InprotechKaizen.Model.Components.Translations
{
    public static class TranslationBuilderExtensions
    {
        public static ITranslationBuilder Include<TEntity>(this ITranslationBuilder builder, IEnumerable<TEntity> items)
            where TEntity : class
        {
            return builder.Include(typeof(TEntity), items);
        }

        public static ITranslationBuilder Include<TEntity>(this ITranslationBuilder builder, TEntity item)
            where TEntity : class
        {
            return builder.Include(typeof(TEntity), new[] { item });
        }

        public static ITranslationBuilder TryInclude<TEntity>(this ITranslationBuilder builder, TEntity item)
            where TEntity : class
        {
            if (item == null)
                return builder;

            return builder.Include(typeof(TEntity), new[] { item });
        }

        public static ITranslationBuilder TryInclude<TEntity, TProperty>(this ITranslationBuilder builder, TEntity item, Expression<Func<TEntity, TProperty>> propertyPath)
            where TEntity : class
        {

            var v = GetValueFromPropertyPath(item, propertyPath.Body);
            if (v == null)
                return builder;

            return builder.Include(v.GetType(), new[] { v });
        }

        static object GetValueFromPropertyPath(object obj, Expression expr)
        {
            if (expr.NodeType == ExpressionType.Parameter)
                return obj;

            var memberSelector = (MemberExpression)expr;

            var r = GetValueFromPropertyPath(obj, memberSelector.Expression);

            if (r == null)
                return null;

            return r.GetType().GetProperty(memberSelector.Member.Name).GetValue(r);
        }
    }
}