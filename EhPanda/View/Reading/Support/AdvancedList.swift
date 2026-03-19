//
//  AdvancedList.swift
//  EhPanda
//

import SwiftUI
import SwiftUIPager

struct AdvancedList<Element, ID, PageView, G>: View
where PageView: View, Element: Equatable, ID: Hashable, G: Gesture {
    @State var performingChanges = false
    @State var scrollPositionID: Int?

    private let pagerModel: Page
    private let data: [Element]
    private let id: KeyPath<Element, ID>
    private let spacing: CGFloat
    private let gesture: G
    private let content: (Element) -> PageView

    init<Data: RandomAccessCollection>(
        page: Page, data: Data,
        id: KeyPath<Element, ID>, spacing: CGFloat, gesture: G,
        @ViewBuilder content: @escaping (Element) -> PageView
    ) where Data.Index == Int, Data.Element == Element {
        self.pagerModel = page
        self.data = .init(data)
        self.id = id
        self.spacing = spacing
        self.gesture = gesture
        self.content = content
    }

    var body: some View {
        if #available(iOS 18, *) {
            iOS18Body
        } else if #available(iOS 17, *) {
            iOS17Body
        } else {
            legacyBody
        }
    }

    @available(iOS 18, *)
    private var iOS18Body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: spacing) {
                    ForEach(data, id: id) { index in
                        content(index)
                            .gesture(gesture)
                    }
                }
                .scrollTargetLayout()
                .onAppear(perform: { tryScrollTo(id: pagerModel.index + 1, proxy: proxy) })
            }
            .scrollPosition(id: $scrollPositionID, anchor: .center)
            .onScrollPhaseChange { _, newValue in
                if newValue == .idle, let index = scrollPositionID {
                    performingChanges = true
                    pagerModel.update(.new(index: index - 1))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        performingChanges = false
                    }
                }
            }
            .onChange(of: pagerModel.index) { _, newValue in
                tryScrollTo(id: newValue + 1, proxy: proxy)
            }
        }
    }

    @available(iOS 17, *)
    private var iOS17Body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: spacing) {
                    ForEach(data, id: id) { index in
                        content(index)
                            .gesture(gesture)
                    }
                }
                .scrollTargetLayout()
                .onAppear(perform: { tryScrollTo(id: pagerModel.index + 1, proxy: proxy) })
            }
            .scrollPosition(id: $scrollPositionID, anchor: .center)
            .onChange(of: scrollPositionID) { _, newValue in
                guard let index = newValue, !performingChanges else { return }
                performingChanges = true
                pagerModel.update(.new(index: index - 1))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    performingChanges = false
                }
            }
            .onChange(of: pagerModel.index) { _, newValue in
                tryScrollTo(id: newValue + 1, proxy: proxy)
            }
        }
    }

    private var legacyBody: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: spacing) {
                    ForEach(data, id: id) { index in
                        content(index)
                            .gesture(gesture)
                    }
                }
                .onAppear(perform: { proxy.scrollTo(pagerModel.index + 1, anchor: .center) })
            }
            .onChange(of: pagerModel.index) { newValue in
                proxy.scrollTo(newValue + 1, anchor: .center)
            }
        }
    }

    private func tryScrollTo(id: Int, proxy: ScrollViewProxy) {
        if !performingChanges {
            scrollPositionID = id
        }
    }
}
