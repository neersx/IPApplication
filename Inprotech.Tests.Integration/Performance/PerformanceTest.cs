using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.Performance
{
    //[TestFixture]
    [Category(Categories.Performance)]
    public class PerformanceTest
    {
        //[Test]
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2202:Do not dispose objects multiple times")]
        public void Test()
        {
            // warm-up
            var wu = Average(1, 1);

            // 1 user
            var sc1 = Average(10, 1);

            // 10 users
            var sc10 = Average(5, 10);

            // 50 users
            var sc50 = Average(3, 50);

            // report

            var filename = @"c:\_temp\performance.html";
            using (var file = File.Open(filename, FileMode.Create, FileAccess.Write))
            {
                using (var writer = new StreamWriter(file))
                {
                    writer.WriteLine("<h2>1 User</h2>");
                    Write(writer, sc1);

                    writer.WriteLine("<hr />");

                    writer.WriteLine("<h2>10 Users</h2>");
                    Write(writer, sc10);

                    writer.WriteLine("<hr />");

                    writer.WriteLine("<h2>50 Users</h2>");
                    Write(writer, sc50);
                }
            }

            Process.Start(new ProcessStartInfo {FileName = filename});
        }

        static void Write(StreamWriter writer, List<PageAveraged> data)
        {
            writer.WriteLine("<style>");
            writer.WriteLine("td, th { padding-right: 20px; }");
            writer.WriteLine("</style>");
            writer.WriteLine("<table>");
            writer.WriteLine("  <tr>");
            writer.WriteLine("      <th>Page</th>");
            writer.WriteLine("      <th>Average</th>");
            writer.WriteLine("      <th>Max</th>");
            writer.WriteLine("      <th>Failed</th>");
            writer.WriteLine("  </tr>");

            foreach (var page in data)
            {
                writer.WriteLine("  <tr>");
                writer.WriteLine("      <td>" + page.Name + "</td>");
                writer.WriteLine("      <td style='text-align:right'>" + page.AvgDuration.FormatSecMsec() + "</td>");
                writer.WriteLine("      <td style='text-align:right'>" + page.MaxDuration.FormatSecMsec() + "</td>");
                writer.WriteLine("      <td style='text-align:right'>" + page.Failed + "</td>");
                writer.WriteLine("  </tr>");
            }

            writer.WriteLine("</table>");
        }

        List<PageAveraged> Average(int repeats, int parallel)
        {
            var results = new ConcurrentBag<List<PageResult>>();

            Parallel.For(0, parallel,
                         new ParallelOptions {MaxDegreeOfParallelism = parallel},
                         x =>
                         {
                             for (var i = 0; i < repeats; i++)
                             {
                                 var sc = new Scenario();
                                 sc.Run();

                                 results.Add(sc.Pages);
                             }
                         });

            return results.Pivot()
                          .Select(x => new PageAveraged
                                       {
                                           Name = x.First().Name,
                                           Failed = x.Count(y => y.Failed),
                                           AvgDuration = x.Average(y => y.Duration),
                                           MaxDuration = x.Max(y => y.Duration)
                                       }).ToList();
        }
    }

    static class Extensions
    {
        internal static IEnumerable<IEnumerable<T>> Pivot<T>(this IEnumerable<List<T>> data)
        {
            var result = new List<List<T>>();

            var i = 0;
            foreach (var ix in data)
            {
                var j = 0;
                foreach (var jx in ix)
                {
                    while (result.Count <= j) result.Add(new List<T>());
                    while (result[j].Count <= i) result[j].Add(default(T));

                    result[j][i] = jx;
                    j++;
                }

                i++;
            }

            return result;
        }

        internal static TimeSpan Average<T>(this IEnumerable<T> ts, Func<T, TimeSpan> selector)
        {
            return TimeSpan.FromTicks((long) ts.Average(x => selector(x).Ticks));
        }

        internal static string FormatSecMsec(this TimeSpan ts)
        {
            return $"{ts.TotalSeconds:0#}.{ts.Milliseconds:000}";
        }
    }
}