# using Printf

# for d in 0:max_diff_resolvable[]+100
#     tests_failed = 0
#     mean_diff = 0
#     max_diff = 0
#     mean_di = 0f0
#     max_di = 0f0
#     for lf1ui in 0x0000:Int16(2^15-d-1)
#         lf2ui = Int16(lf1ui + d)

#         lf1 = reinterpret(LogFixPoint16,lf1ui)
#         lf2 = reinterpret(LogFixPoint16,lf2ui)

#         r = Float32(lf1)+Float32(lf2)
#         result = LogFixPoint16(r)
#         result2 = lf1+lf2

#         ui1 = reinterpret(UInt16,result)
#         ui2 = reinterpret(UInt16,result2)

#         # filter out nans
#         failed = (ui1 == 0x8000 || ui2 == 0x8000) ? false : ui1 != ui2
#         tests_failed += failed

#         if failed
#             mean_diff += Int(ui1)-Int(ui2)
#             max_diff = max(abs(Int(ui1)-Int(ui2)),max_diff)
#             di = Float32.([prevfloat(result2),result2,nextfloat(result2)]) .- r
#             di = sort(abs.(di))[1:2]
#             dir = di[2]/sum(di)
#             mean_di += dir
#             max_di = max(max_di,dir)
#             # if dir > 0.7
#             #     println([lf1,lf2])
#             # end
#         end
#     end
#     if tests_failed > 0
#         ds = @sprintf("%4d",d)
#         ps = @sprintf("%5d",2^15-d-tests_failed)
#         fs = @sprintf("%5d",tests_failed)
#         ms = @sprintf("%2d",Int(mean_diff/tests_failed))
#         dis = @sprintf("%.6f",mean_di/tests_failed)
#         mdis = @sprintf("%.6f",max_di)
#         println("d=$ds, Pass: $ps, Fail: $fs, Diff: $ms, Mean dist: $dis, Max dist: $mdis")
#     end
# end

# # d=   1, Pass: 22623, Fail: 10144, Max diff: 1
# # d= 267, Pass: 32244, Fail:   257, Max diff: 1
# # d= 431, Pass: 29175, Fail:  3162, Max diff: 1
# # d= 512, Pass: 30577, Fail:  1679, Max diff: 1
# # d= 780, Pass: 31756, Fail:   232, Max diff: 1
# # d=1407, Pass: 30983, Fail:   378, Max diff: 1
# # d=1898, Pass: 16955, Fail: 13915, Max diff: 1
# # d=2364, Pass: 27703, Fail:  2701, Max diff: 1
# # d=2390, Pass: 23380, Fail:  6998, Max diff: 1
# # d=2535, Pass: 18473, Fail: 11760, Max diff: 1
# # d=3211, Pass: 25052, Fail:  4505, Max diff: 1
# # d=3493, Pass: 29253, Fail:    22, Max diff: 1
# # d=4201, Pass: 28545, Fail:    22, Max diff: 1
# # d=4578, Pass: 27461, Fail:   729, Max diff: 1
# # d=4579, Pass: 28188, Fail:     1, Max diff: 1
# # d=5389, Pass: 26733, Fail:   646, Max diff: 1
# # d=5390, Pass: 21643, Fail:  5735, Max diff: 1
# # d=5391, Pass: 23039, Fail:  4338, Max diff: 1
# # d=5392, Pass: 27367, Fail:     9, Max diff: 1

# for d in 0:max_diff_resolvable[]+100
#     tests_failed = 0
#     mean_diff = 0
#     max_diff = 0
#     mean_di = 0f0
#     max_di = 0f0
#     for lf1ui in 0x0000:Int16(2^15-d-1)
#         lf2ui = Int16(lf1ui + d)

#         lf1 = reinterpret(LogFixPoint16,lf1ui)
#         lf2 = reinterpret(LogFixPoint16,lf2ui)

#         r = Float32(lf2)-Float32(lf1)
#         result = LogFixPoint16(r)
#         result2 = lf2-lf1

#         ui1 = reinterpret(UInt16,result)
#         ui2 = reinterpret(UInt16,result2)

#         # filter out nans
#         failed = (ui1 == 0x8000 || ui2 == 0x8000) ? false : ui1 != ui2
#         tests_failed += failed

#         if failed
#             mean_diff += Int(ui1)-Int(ui2)
#             max_diff = max(abs(Int(ui1)-Int(ui2)),max_diff)
#             di = Float32.([prevfloat(result2),result2,nextfloat(result2)]) .- r
#             di = sort(abs.(di))[1:2]
#             dir = di[2]/sum(di)
#             mean_di += dir
#             max_di = max(max_di,dir)
#             # if dir > 0.7
#             #     println([lf1,lf2])
#             # end
#         end
#     end
#     if tests_failed > 0
#         ds = @sprintf("%4d",d)
#         ps = @sprintf("%5d",2^15-d-tests_failed)
#         fs = @sprintf("%5d",tests_failed)
#         ms = @sprintf("%2d",max_diff)
#         dis = @sprintf("%.6f",mean_di/tests_failed)
#         mdis = @sprintf("%.6f",max_di)
#         println("d=$ds, Pass: $ps, Fail: $fs, Diff: $ms, Mean dist: $dis, Max dist: $mdis")
#     end
# end

# er = fill(0f0,11760)
# for d in [2535]
#     i = 1
#     for lf1ui in 0x0000:Int16(2^15-d-1)
#         lf2ui = Int16(lf1ui + d)

#         lf1 = reinterpret(LogFixPoint16,lf1ui)
#         lf2 = reinterpret(LogFixPoint16,lf2ui)

#         result = Float32(lf1)+Float32(lf2)
#         if reinterpret(UInt16,LogFixPoint16(result)) != reinterpret(UInt16,lf1+lf2)
#             di = Float32.([lf1+lf2,nextfloat(lf1+lf2)]) .- result
#             er[i] = abs(di[1])/sum(abs.(di))
#             i += 1
#         end
#     end
# end

# for d in 0:10000
#     tests_failed = 0
#     max_diff = 0
#         for lf1ui in 0x0000:Int16(2^15-d-1)
#             lf2ui = Int16(lf1ui + d)

#             lf1 = reinterpret(LogFixPoint16,lf1ui)
#             lf2 = reinterpret(LogFixPoint16,lf2ui)

#             result = LogFixPoint16(Float32(lf2)-Float32(lf1))
#             tests_failed += reinterpret(UInt16,result) != reinterpret(UInt16,lf2-lf1)
#             max_diff = max(max_diff,abs(Int(reinterpret(UInt16,result))-Int(reinterpret(UInt16,lf2-lf1))))
#         end
#         if tests_failed > 0
#             ds = @sprintf("%4d",d)
#             ps = @sprintf("%5d",2^15-d-tests_failed)
#             fs = @sprintf("%5d",tests_failed)
#             println("d=$ds, Pass: $ps, Fail: $fs, Max diff: $max_diff")
#         end
#     end
# end

# # @testset "addition all" begin
# R = fill(Int32(0),1000,6)
# i = 1
# for _ in 1:10000000
#     lf1ui,lf2ui = rand(UInt16,2)

#     # abs to only test the addTable
#     lf1 = abs(reinterpret(LogFixPoint16,lf1ui))
#     lf2 = abs(reinterpret(LogFixPoint16,lf2ui))

#     result = LogFixPoint16(Float32(lf1)+Float32(lf2))
#     if reinterpret(UInt16,result) != reinterpret(UInt16,lf1+lf2)
#         R[i,1:end-1] = vcat([diff_val(lf1,lf2)],reinterpret.(UInt16,[lf1,lf2,result,lf1+lf2]))
#         R[i,end] = Int(reinterpret(UInt16,result)) - Int(reinterpret(UInt16,lf1+lf2))
#         global i += 1
#         global i = min(i,1000)
#     end
# end
# # end
