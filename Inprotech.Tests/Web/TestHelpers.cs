using System;
using System.Linq.Expressions;
using System.Reflection;

namespace Inprotech.Tests.Web
{
    public static class TestHelpers
    {
        public static string[] SplitCommaSeparateValues(this string value)
        {
            return value.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries);
        }

        public static T WithKnownId<T, TId>(this T entity, TId id) where T : class
        {
            entity.GetType().GetProperty("Id").SetValue(entity, id, null);
            return entity;
        }

        public static T WithKnownId<T, TId>(this T entity, Expression<Func<T, int>> keyPropertySelector, TId id) where T : class
        {
            var expr = keyPropertySelector.Body as MemberExpression ?? (MemberExpression) ((UnaryExpression) keyPropertySelector.Body).Operand;

            var property = (PropertyInfo) expr.Member;

            property.SetValue(entity, id, null);

            return entity;
        }

        public static T WithKnownId<T, TId>(this T entity, Expression<Func<T, short>> keyPropertySelector, TId id) where T : class
        {
            var expr = keyPropertySelector.Body as MemberExpression ?? (MemberExpression) ((UnaryExpression) keyPropertySelector.Body).Operand;

            var property = (PropertyInfo) expr.Member;

            property.SetValue(entity, id, null);

            return entity;
        }
    }
}