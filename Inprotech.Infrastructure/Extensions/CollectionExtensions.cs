using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using Inprotech.Infrastructure.Web;

// ReSharper disable PossibleMultipleEnumeration
// ReSharper disable PossibleNullReferenceException

namespace Inprotech.Infrastructure.Extensions
{
    public static class CollectionExtensions
    {
        public enum FilterOperator
        {
            In,
            NotIn,

            /// <summary>
            ///     Greater Than
            /// </summary>
            Gt,

            /// <summary>
            ///     Greater Than Or Equal To
            /// </summary>
            Gte,

            /// <summary>
            ///     Less Than
            /// </summary>
            Lt,

            /// <summary>
            ///     Equals
            /// </summary>
            Eq,

            StartsWith,

            Contains
        }

        const BindingFlags Flags = BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance;

        public const string NullString = "null";

        public static void AddRange<T>(this ICollection<T> collection, IEnumerable<T> items)
        {
            if (collection == null) throw new ArgumentNullException(nameof(collection));
            if (items == null) throw new ArgumentNullException(nameof(items));

            foreach (var item in items)
                collection.Add(item);
        }

        public static void InChunksOf<T>(this IEnumerable<T> items, int size, Action<IEnumerable<T>> perChunkAction)
        {
            if (items == null) throw new ArgumentNullException(nameof(items));
            if (perChunkAction == null) throw new ArgumentNullException(nameof(perChunkAction));

            var all = new List<T>(items);
            var currentChunk = all.Take(size).ToArray();

            while (currentChunk.Any())
            {
                all = all.Except(currentChunk).ToList();

                perChunkAction(currentChunk);

                currentChunk = all.Take(size).ToArray();
            }
        }

        /// <summary>
        ///     Dynamically generates expression tree for sorting
        /// </summary>
        /// <typeparam name="TEntity"></typeparam>
        /// <param name="source"></param>
        /// <param name="qp">
        ///     Instance of Common Query Param. Returns the original source if SortBy is null
        /// </param>
        /// <returns></returns>
        public static IOrderedQueryable<TEntity> OrderByProperty<TEntity>(this IQueryable<TEntity> source, CommonQueryParameters qp) where TEntity : class
        {
            if (qp == null || string.IsNullOrEmpty(qp.SortBy))
            {
                return source as IOrderedQueryable<TEntity>;
            }

            return source.OrderByProperty(qp.SortBy, qp.SortDir);
        }

        /// <summary>
        ///     Dynamically generates expression tree for sorting
        /// </summary>
        /// <typeparam name="TEntity"></typeparam>
        /// <param name="source"></param>
        /// <param name="orderByProperty">
        ///     The path of property which supports nested property access e.g.
        ///     entity.ReleaseVersion.Sequence. Returns data sorted by 1st column if "orderByProperty" is null
        /// </param>
        /// <param name="orderByDirection"></param>
        /// <returns></returns>
        public static IOrderedQueryable<TEntity> OrderByProperty<TEntity>(this IQueryable<TEntity> source, string orderByProperty, string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source.OrderBy(_ => 1); //todo: review
            }

            var type = typeof(TEntity);

            var parameter = Expression.Parameter(type);

            var propertyAccessExpr = BuildPropertyPathAccessExpression(type, parameter, orderByProperty);
            var propertyType = propertyAccessExpr.Type;
            var orderByExpression = Expression.Lambda(propertyAccessExpr, parameter);

            var command = IsDescending(orderByDirection) ? "OrderByDescending" : "OrderBy";
            var resultExpression = Expression.Call(typeof(Queryable), command, new[] { type, propertyType },
                                                   source.Expression, Expression.Quote(orderByExpression));

            return source.Provider.CreateQuery<TEntity>(resultExpression) as IOrderedQueryable<TEntity>;
        }

        public static IOrderedQueryable<T> OrderForPicklist<T>(this IOrderedQueryable<T> source,
                                                               Expression<Func<T, string>> code,
                                                               Expression<Func<T, string>> desc,
                                                               string search) where T : class
        {
            if (string.IsNullOrEmpty(search)) return source;// source.OrderBy(_ => 1);

            var t = typeof(T);

            Expression codeSafe = null, descSafe = null;
            Expression codeLowercase = null, descLowercase = null;
            Expression codeExactMatch = null, descExactMatch = null;
            Expression codeStartsWith = null, descStartsWith = null;
            Expression codeContains = null, descContains = null;

            //Expression<Func<string>> searchLowercase = () => search.ToLower();
            var searchLowercase = Expression.Constant(search.ToLower());

            if (code != null)
            {
                codeSafe = Expression.Coalesce(code.Body, Expression.Constant(string.Empty));
                codeLowercase = Expression.Call(codeSafe, typeof(string).GetMethod("ToLower", new Type[] { }));
                codeExactMatch = Expression.Equal(codeLowercase, searchLowercase);

                codeStartsWith = Expression.Call(codeLowercase,
                                                 typeof(string).GetMethod("StartsWith", new[] { typeof(string) }),
                                                 searchLowercase);

                codeContains = Expression.Call(codeLowercase,
                                               typeof(string).GetMethod("Contains", new[] { typeof(string) }),
                                               searchLowercase);
            }

            if (desc != null)
            {
                descSafe = Expression.Coalesce(desc.Body, Expression.Constant(string.Empty));
                descLowercase = Expression.Call(descSafe, typeof(string).GetMethod("ToLower", new Type[] { }));
                descExactMatch = Expression.Equal(descLowercase, searchLowercase);

                descStartsWith = Expression.Call(descLowercase,
                                                 typeof(string).GetMethod("StartsWith", new[] { typeof(string) }),
                                                 searchLowercase);

                descContains = Expression.Call(descLowercase,
                                               typeof(string).GetMethod("Contains", new[] { typeof(string) }),
                                               searchLowercase);
            }

            // exact match on description
            Expression expr = Expression.Call(typeof(Queryable),
                                              "ThenBy",
                                              new[] { t, typeof(int) },
                                              source.Expression, Expression.Lambda(Expression.Condition(descExactMatch,
                                                                                                        Expression.Constant(0),
                                                                                                        Expression.Constant(1)),
                                                                                   desc.Parameters));

            // exact match on code
            if (code != null) expr = ThenByPredicate(expr, codeExactMatch, code.Parameters, t);

            // code starts with
            if (code != null) expr = ThenByPredicate(expr, codeStartsWith, code.Parameters, t);

            // description starts with
            expr = ThenByPredicate(expr, descStartsWith, desc.Parameters, t);

            // code contains
            if (code != null) expr = ThenByPredicate(expr, codeContains, code.Parameters, t);

            // description contains
            expr = ThenByPredicate(expr, descContains, desc.Parameters, t);

            // description
            expr = Expression.Call(typeof(Queryable),
                                   "ThenBy",
                                   new[] { t, typeof(string) },
                                   expr, Expression.Lambda(descSafe, desc.Parameters));

            return source.Provider.CreateQuery<T>(expr) as IOrderedQueryable<T>;
        }

        private static Expression ThenByPredicate(Expression expr, Expression predicate, IEnumerable<ParameterExpression> parameters, Type t)
        {
            return Expression.Call(typeof(Queryable),
                                   "ThenBy",
                                   new[] { t, typeof(int) },
                                   expr, Expression.Lambda(Expression.Condition(predicate,
                                                                                Expression.Constant(0),
                                                                                Expression.Constant(1)),
                                                           parameters));
        }

        public static IOrderedQueryable<TEntity> ThenByProperty<TEntity>(this IOrderedQueryable<TEntity> source,
                                                                         string orderByProperty,
                                                                         string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source;
            }

            var type = typeof(TEntity);

            var parameter = Expression.Parameter(type);

            var propertyAccessExpr = BuildPropertyPathAccessExpression(type, parameter, orderByProperty);
            var propertyType = propertyAccessExpr.Type;
            var orderByExpression = Expression.Lambda(propertyAccessExpr, parameter);

            var command = IsDescending(orderByDirection) ? "ThenByDescending" : "ThenBy";
            var resultExpression = Expression.Call(typeof(Queryable), command, new[] { type, propertyType },
                                                   source.Expression, Expression.Quote(orderByExpression));

            return source.Provider.CreateQuery<TEntity>(resultExpression) as IOrderedQueryable<TEntity>;
        }

        public static IOrderedEnumerable<TEntity> OrderByProperty<TEntity>(this IEnumerable<TEntity> source,
                                                                           string orderByProperty,
                                                                           string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source.OrderBy(_ => 1);
            }

            return IsDescending(orderByDirection)
                ? source.OrderByDescending(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null))
                : source.OrderBy(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null));
        }

        public static IOrderedEnumerable<TEntity> OrderByNumeric<TEntity>(this IEnumerable<TEntity> source,
                                                                           string orderByProperty,
                                                                           string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source.OrderBy(_ => 1);
            }

            return IsDescending(orderByDirection)
                ? source.OrderByDescending(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null), new NumericComparer())
                : source.OrderBy(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null), new NumericComparer());
        }

        public static IOrderedEnumerable<TEntity> ThenByProperty<TEntity>(this IOrderedEnumerable<TEntity> source,
                                                                          string orderByProperty,
                                                                          string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source;
            }

            return IsDescending(orderByDirection)
                ? source.ThenByDescending(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null))
                : source.ThenBy(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null));
        }

        public static IOrderedEnumerable<TEntity> ThenByNumeric<TEntity>(this IOrderedEnumerable<TEntity> source,
                                                                          string orderByProperty,
                                                                          string orderByDirection) where TEntity : class
        {
            if (string.IsNullOrEmpty(orderByProperty))
            {
                return source;
            }

            return IsDescending(orderByDirection)
                ? source.ThenByDescending(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null), new NumericComparer())
                : source.ThenBy(x => x.GetType().GetProperty(orderByProperty, Flags).GetValue(x, null), new NumericComparer());
        }

        static bool IsDescending(string orderByDirection)
        {
            return string.Compare(orderByDirection, "desc", StringComparison.OrdinalIgnoreCase) == 0;
        }

        public static IOrderedEnumerable<TEntity> ThenByNullsLast<TEntity>(this IOrderedEnumerable<TEntity> source, string orderByProperty)
        {
            return source.ThenBy(x => string.IsNullOrEmpty(Convert.ToString(x.GetType().GetProperty(orderByProperty).GetValue(x, null))))
                         .ThenBy(x => x.GetType().GetProperty(orderByProperty).GetValue(x, null));
        }

        public static IOrderedEnumerable<TEntity> ThenByNullsLastDescending<TEntity>(this IOrderedEnumerable<TEntity> source, string orderByProperty)
        {
            return source.ThenBy(x => string.IsNullOrEmpty(x.GetType().GetProperty(orderByProperty).GetValue(x, null) as string))
                         .ThenByDescending(x => x.GetType().GetProperty(orderByProperty).GetValue(x, null));
        }

        public static IEnumerable<TEntity> FilterByProperty<TEntity>(this IEnumerable<TEntity> source, string propertyPath, string operatorType, DateTime? value) where TEntity : class
        {
            var source2 = source as IQueryable<TEntity> ?? source.AsQueryable();
            return FilterByProperty(source2, propertyPath, operatorType, value);
        }

        public static IQueryable<TEntity> FilterByProperty<TEntity>(this IQueryable<TEntity> source, string propertyPath, string operatorType, DateTime? value) where TEntity : class
        {
            if (!Enum.TryParse(operatorType, true, out FilterOperator filterOp)) return source;

            var type = typeof(TEntity);
            var parameter = Expression.Parameter(type);

            var propertyAccessExpr = BuildPropertyPathAccessExpression(type, parameter, propertyPath);

            Expression predicateExpr;

            switch (filterOp)
            {
                case FilterOperator.Eq:
                    var start = value.GetValueOrDefault().Date;
                    var end = value.GetValueOrDefault().AddDays(1).Date;

                    var startExpr = Expression.GreaterThanOrEqual(propertyAccessExpr,
                                                                  Expression.Constant(start, propertyAccessExpr.Type));

                    var endExpr = Expression.LessThan(propertyAccessExpr,
                                                      Expression.Constant(end, propertyAccessExpr.Type));

                    predicateExpr = Expression.And(startExpr, endExpr);
                    break;

                case FilterOperator.Gt:
                    predicateExpr = Expression.GreaterThan(propertyAccessExpr,
                                                           Expression.Constant(value, propertyAccessExpr.Type));
                    break;

                case FilterOperator.Gte:
                    predicateExpr = Expression.GreaterThanOrEqual(propertyAccessExpr,
                                                                  Expression.Constant(value, propertyAccessExpr.Type));
                    break;

                case FilterOperator.Lt:
                    predicateExpr = Expression.LessThan(propertyAccessExpr,
                                                        Expression.Constant(value, propertyAccessExpr.Type));
                    break;

                default:
                    throw new NotSupportedException($"This filter {operatorType} is currently not supported.");
            }

            var whereExpr = Expression.Call(typeof(Queryable), "Where", new[] { type }, source.Expression, Expression.Lambda<Func<TEntity, bool>>(predicateExpr, parameter));

            return source.Provider.CreateQuery<TEntity>(whereExpr);
        }

        public static IEnumerable<TEntity> FilterByProperty<TEntity>(this IEnumerable<TEntity> source, string propertyPath, string operatorType, string value, bool filterEmptyString = false) where TEntity : class
        {
            var source2 = source as IQueryable<TEntity> ?? source.AsQueryable();
            return FilterByProperty(source2, propertyPath, operatorType, value, filterEmptyString);
        }

        public static IQueryable<TEntity> FilterByProperty<TEntity>(this IQueryable<TEntity> source, string propertyPath, string operatorType, string value, bool filterEmptyString = false) where TEntity : class
        {
            if (!Enum.TryParse(operatorType, true, out FilterOperator filterOp)) return source;

            var type = typeof(TEntity);
            var parameter = Expression.Parameter(type);

            var propertyAccessExpr = BuildPropertyPathAccessExpression(type, parameter, propertyPath);
            var propertyType = propertyAccessExpr.Type;

            if (filterOp == FilterOperator.In || filterOp == FilterOperator.NotIn)
            {
                var strValues = !filterEmptyString
                    ? value.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries).Select(_ => _ == NullString ? null : _.Trim()).ToArray()
                    : value.Split(new[] { ',' }).Select(x => x == "empty" ? null : x.Trim()).ToArray();

                ConstantExpression itemsExpr;
                if (propertyType == typeof(string))
                {
                    itemsExpr = Expression.Constant(strValues);
                }
                else
                {
                    var values = strValues.Select(x => TypeConversionExtensions.GetValue(x, propertyType)).ToArray();
                    var array = Array.CreateInstance(propertyType, strValues.Length);

                    Array.Copy(values, array, array.Length);
                    itemsExpr = Expression.Constant(array);
                }

                Expression predicateExpr = Expression.Call(typeof(Enumerable), "Contains", new[] { propertyType }, itemsExpr, propertyAccessExpr);

                if (filterOp == FilterOperator.NotIn)
                {
                    predicateExpr = Expression.Not(predicateExpr);
                }

                var whereExpr = Expression.Call(typeof(Queryable), "Where", new[] { type }, source.Expression, Expression.Lambda(predicateExpr, parameter));

                return source.Provider.CreateQuery<TEntity>(whereExpr);
            }

            Expression predicateExpr2;
            switch (filterOp)
            {
                case FilterOperator.Eq:
                    predicateExpr2 = Expression.Equal(propertyAccessExpr, Expression.Constant(value, propertyAccessExpr.Type));
                    break;

                case FilterOperator.StartsWith:
                case FilterOperator.Contains:

                    var operatorMethod = filterOp.ToString();
                    var c = Expression.Constant(value, typeof(string));
                    var mi = typeof(string).GetMethod(operatorMethod, new[] { typeof(string) });
                    predicateExpr2 = Expression.Call(propertyAccessExpr, mi, c);
                    break;

                default:
                    throw new NotSupportedException($"This filter {operatorType} is currently not supported.");
            }

            var whereExpr2 = Expression.Call(typeof(Queryable), "Where", new[] { type }, source.Expression, Expression.Lambda<Func<TEntity, bool>>(predicateExpr2, parameter));

            return source.Provider.CreateQuery<TEntity>(whereExpr2);
        }

        public static IQueryable<TEntity> Filter<TEntity>(this IQueryable<TEntity> source, CommonQueryParameters queryParameters) where TEntity : class
        {
            var result = source;

            foreach (var f in queryParameters.Filters)
            {
                switch (f.Type)
                {
                    case "date":
                        result = result.FilterByProperty(f.Field, f.Operator, f.DateTimeValue);
                        break;

                    default:
                        result = result.FilterByProperty(f.Field, f.Operator, f.Value);
                        break;
                }
            }

            return result;
        }

        static MemberExpression BuildPropertyPathAccessExpression(Type type, Expression root, string path)
        {
            var props = path.Split('.');
            var t = type;
            var expr = root;

            foreach (var prop in props)
            {
                var p = t.GetProperty(prop, BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);
                if (p == null) throw new Exception("cannot find property " + path + " on type " + type);

                expr = Expression.MakeMemberAccess(expr, p);

                t = p.PropertyType;
            }

            return (MemberExpression)expr;
        }

        public static bool IsOrdered<T, TKey>(this IEnumerable<T> source, Func<T, TKey> keySelector)
        {
            if (source == null) throw new ArgumentNullException(nameof(source));

            var comparer = Comparer<TKey>.Default;
            using (var iterator = source.GetEnumerator())
            {
                if (!iterator.MoveNext()) return true;

                TKey current = keySelector(iterator.Current);

                while (iterator.MoveNext())
                {
                    TKey next = keySelector(iterator.Current);
                    if (comparer.Compare(current, next) > 0)
                        return false;

                    current = next;
                }
            }

            return true;
        }
    }
}