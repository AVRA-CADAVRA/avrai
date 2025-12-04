# Local Expert System Redesign - Complete Requirements

**Created:** November 23, 2025  
**Status:** 📋 Requirements Document  
**Purpose:** Comprehensive redesign of expert system to prioritize local experts and enable community events

---

## 🎯 **Core Philosophy**

**Local experts are the bread and butter of SPOTS.** They don't need to expand past their locality to be qualified. The system should prioritize local experts hosting in their locality over city/state/national experts hosting in that same locality.

**Key Principle:** This is NOT about comparing experts—it's about helping users find likeminded people and explore new things/places/spaces/spots.

---

## 📍 **Geographic Hierarchy & Event Hosting**

### **Hierarchy (Confirmed Correct):**

```
National Expert
  └─ Can host in: All states, cities, and localities in their nation

State Expert  
  └─ Can host in: All cities and localities in their state

City Expert (e.g., NYC Expert)
  └─ Can host in: All localities/boroughs in their city (all 5 boroughs for NYC)
  └─ Can choose to host for specific locality, type of user, etc. (as long as in their city)

Local Expert (e.g., Brooklyn Local Expert)
  └─ Can host in: Only their locality (Brooklyn only, NOT Manhattan)
  └─ Can host ALL types of events in their locality (including house parties)
```

### **Special Case: Large Diverse Cities**

**Problem:** Large cities (Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.) have neighborhoods that are vastly different in thought, atmosphere, idea, and identity.

**Solution:** Neighborhoods in these cities should be separate localities.

**Detection Criteria:**
System should recognize "large and diverse" cities based on:
1. **Geographic size** (e.g., Houston is huge with many towns inside)
2. **Population size**
3. **Well-documented neighborhoods** backed by geography and population data

**Example - Brooklyn:**
- Greenpoint, Bath Beach, Sunset Park, DUMBO are **different localities**
- A user in Greenpoint can attend a Bath Beach event and feel like a "local"
- This preserves neighborhood identity and diversity
- Promotes value of small events
- Allows exploration between neighborhoods while maintaining their unique character

**Example Scenario:**
- User from Sunset Park enjoys mahjong
- Mahjong event hosted in DUMBO
- User can feel like a local going to a local event, even if it's not in their locality

**Implementation:**
- System should recognize when a city is "large and diverse"
- Allow neighborhoods to be separate localities
- Users from one neighborhood can attend events in another and feel "local"

### **Neighborhood Boundaries:**

**Source:** Neighborhood boundaries can usually be found on Google Maps.

**Hard vs Soft Borders:**
- **Hard borders:** Well-defined boundaries (e.g., NoHo and SoHo have clear borders)
- **Soft borders:** Not well-defined (e.g., Nolita and East Village blend together)

**Soft Border Handling:**
- If a spot is in a soft border area, it can be **shared with both localities**
- As users go to said spot, the AI tracks who is going where
- If one locality goes to a spot more than another, the locality borders become **more defined over time**
- System learns and refines boundaries based on actual user behavior

**Dynamic Border Definition:**
- Borders are not static
- AI continuously tracks user movement patterns
- If users from Locality A consistently visit a spot more than users from Locality B, that spot becomes more associated with Locality A
- Borders evolve based on actual community behavior

---

## 🎪 **Event Hosting Requirements**

### **Local Experts:**
- ✅ Can host **ALL types of events** in their locality
- ✅ Including house parties
- ✅ Lower threshold to qualify than city experts
- ✅ Can host in their locality only (not other localities)

### **City Experts:**
- ✅ Can host in all localities within their city
- ✅ Can choose to host for specific locality, type of user, etc.
- ✅ Must have expertise across city (more than just one neighborhood)

### **Community Events (Non-Experts):**
- ✅ Non-experts can host public events (dinner parties, park hangs, walks, runs, etc.)
- ✅ **Cannot charge on app** (cash at door OK)
- ✅ If community events get following and are hosted frequently, host can upgrade to "local event"
- ✅ Community events appear in "Community" section of events page

### **Events Page Organization:**

Users should see suggested events organized by scope:

1. **Community** - Non-expert events (friends on app, contacts)
2. **Locality** - Events in user's locality
3. **City** - Events in user's city
4. **State** - Events in user's state
5. **Nation** - Events in user's nation
6. **Globe** - Global events
7. **Universe** - Universal events
8. **Clubs/Communities** - All club and community events (uniform tab)

---

## 🏆 **Reputation & Event Matching System**

### **Purpose:**
NOT to compare experts, but to:
- Help users find likeminded people
- Match users to events they'll like
- Enable exploration of new things/places/spaces/spots

### **Reputation Score Components:**

Reputation should be based on all of these factors:
- Number of successful events hosted
- Average event ratings
- SPOTS followers
- External social following (Instagram, TikTok, etc.)
- Community recognition
- Peer endorsements
- **Growth of event size per user** (more community building = more respect)
- **Active respects to lists** (more active respects to a list = more respect to user's reputation score)

### **Reputation Calculation (Locality-Specific):**

**The math should be based on what the locality wants:**

1. **Locality-Specific Weighting:**
   - Each locality values different things
   - If locality values event hosting → events hosted weighted higher
   - If locality values list curation → list respects weighted higher
   - If locality values community building → event growth weighted higher

2. **Geographic Interaction Patterns:**
   - How users interact with geography affects reputation
   - Example: Do people from Brooklyn go to Manhattan more than people from Manhattan go to Brooklyn?
   - What draws users to different localities?
   - Reputation reflects actual community movement patterns

3. **Community Building Metrics:**
   - **Growth of event size per user:** More community building = more respect
   - Events that grow in size show community value
   - **Active respects to lists:** More active respects = more respect to reputation
   - Lists that get frequent respects show community value

**Example:**
- User hosts coffee events in Greenpoint
- Events grow from 5 → 10 → 20 attendees (community building)
- User's coffee list gets 50 active respects (users actively engaging)
- Greenpoint values community building and local curation
- Reputation score reflects these locality values

**Note:** This is a matching system, not a competitive ranking. The goal is connecting likeminded people, not comparing experts.

### **Local Expert Priority:**

**Rule:** Local expert hosting in their locality should be prioritized over city expert hosting in that same locality.

**Example:**
- Local expert hosting coffee event in Greenpoint
- City expert hosting coffee event in Greenpoint
- **Local expert's event should rank higher** (assuming similar matching signals - events hosted, ratings, followers, etc.)

### **User Preference Learning:**

**If user prefers (by frequency):**
- Local events by local experts → Show more local events by local experts
- But also suggest events outside typical behavior (e.g., user likes trivia, suggest improv show at neighboring bar)

**If user prefers:**
- Events hosted by city experts → Show city expert events, but also suggest local events by local/state/national/global/universal experts

### **Cross-Locality Sharing:**

**Rule:** Local experts who host many successful events should be shared with people in connected localities.

**Purpose:** Bring likeminded individuals around the locality into the locality so those people can find more likeminded individuals and therefore community.

**"Neighboring" Definition:**
- NOT just about geographic distance
- Based on how **connected** places are:
  - How people interact (commute to work, travel, fun, etc.)
  - Transportation methods (car, bus, walking, boat, subway, tram, etc.)
  - Shared metropolitan/municipal areas
  - User behavior patterns (where people actually go)

**Example - Birmingham Metro Area:**
- Birmingham AL, Hoover AL, Vestavia Hills, Mountain Brook, Bessemer, Irondale, Avondale, etc.
- These localities have diverse lifestyles but share connections
- Irondale and Hoover might not share borders, but are in same metro area
- Events from one can be shared in "City" tab (Birmingham metro)
- If users from Hoover frequently attend events in Irondale (or vice versa), they become "connected"

**Example - NYC:**
- Local expert in Greenpoint hosts many successful coffee events
- System should show these events to users in connected localities (Williamsburg, Long Island City, etc.)
- Based on actual user travel patterns and connections, not just distance

---

## 🎓 **Local Expert Qualification**

### **Dynamic Thresholds:**
Local experts should have **lower thresholds** than city experts, but thresholds should **ebb and flow** based on locality data.

### **Qualification Factors:**

Users become local experts when they:

1. **Create lists that others follow** focused on certain areas and certain things
   - Example: User creates very popular list for coffee shops in Greenpoint
   - That person can then become an expert on the topic

2. **Going to events** (attendance and engagement)

3. **Hosting events** (successful event hosting)

4. **Background in the topic** (professional experience, credentials)

5. **Peer reviewed reviews** (reviews that get peer endorsements)

6. **Positive activity trends** with a certain topic and place
   - Consistent engagement with category + locality
   - Quality contributions over time

### **Threshold Calculation:**

**All data should be looked at**, but **what users interact with most** (care about most) in each locality should take precedence in determining thresholds.

**Example:**
- In Greenpoint, users interact heavily with coffee lists and events
- Coffee expertise threshold might be lower (easier to achieve) because it's what the community values
- In same locality, users don't interact much with art galleries
- Art gallery expertise threshold might be higher (harder to achieve) because it's less valued by the community

**Key Point:**
Local experts **shouldn't have to expand past their locality to be qualified.** They can be experts in their neighborhood without needing city-wide expertise. Thresholds adapt to what the locality actually values.

---

## ✨ **Golden Local Expert AI Influence**

### **Role:**
Golden Local Experts are **locality representatives.**

### **AI Personality Influence:**

Their behavior should influence AI personality at **10% higher rate** (proportional to residency length):

- **What they go to** (spots they visit)
- **What they do** (activities, events)
- **Who they're friends with** (connections, community)

### **System Impact:**

1. **AI Personality Representation:**
   - Golden expert's behavior influences how AI personality represents that locality
   - 10% higher weight (proportional to residency length)
   - Example: 30 years = 1.3x weight, 25 years = 1.25x weight

2. **Central AI System Interpretation:**
   - How the central AI system interprets the locality to other AIs
   - Golden expert's perspective shapes this interpretation

3. **List/Review Weighting:**
   - Their lists/reviews should be **weighted more heavily** in locality recommendations
   - Higher influence on what spots/places are recommended

4. **Neighborhood Character:**
   - Their expertise should shape the **character of that neighborhood** in the system
   - Along with all local users/experts, but at higher rate
   - They help define what the neighborhood "is"

### **Implementation:**
- Golden expert actions get 1.1x to 1.3x weight (based on residency length)
- Their preferences influence locality AI personality
- Their lists/reviews have higher weight in recommendations
- They help shape neighborhood "vibe" in the system

---

## 🔄 **Community Event Upgrade Path**

### **Process:**

1. **User hosts community event** (non-expert)
2. **Event gets following** (users attend, engage)
3. **Event is hosted frequently** (recurring or multiple instances)
4. **Host can upgrade to "local event"** (becomes local expert event)
5. **Event now appears in Locality section** (not just Community)

---

## 👥 **Events Creating Communities & Clubs**

### **Core Concept:**

**Events can create communities**, and **communities can be treated like clubs** with organizational structure.

### **Club Structure:**

Clubs have:
- **Leaders** (founders, primary organizers)
- **Admin team** (managers, moderators)
- **Internal hierarchy** (roles, responsibilities, permissions)

### **Geographic Expansion:**

**Events hosted by communities/clubs can expand past the original locality:**

- **Original locality** → Starting point
- **Another locality** → Expand to neighboring/connected localities
- **City** → Expand across city
- **State** → Expand across state
- **Nation** → Expand across nation
- **Globe** → Expand globally
- **Universe** → Universal reach

**Example:**
- User creates "Greenpoint Coffee Walk" event in Greenpoint
- Event becomes popular, creates community
- Community becomes a club: "Greenpoint Coffee Club"
- Club hosts events that expand to:
  - Williamsburg (another locality)
  - All of Brooklyn (city)
  - NYC metro area (state)
  - Nationwide (nation)
  - Globally (globe)

### **Expertise Gain from Expansion (Detailed Process):**

**Step-by-Step Process:**

1. **Initial Event Creation:**
   - User creates event in their locality (e.g., Gowanus)
   - User has local expertise in Gowanus

2. **Neighboring Locality Expansion:**
   - Event grows to include people from neighboring localities
   - Those people then create an event in their locality
   - **Result:** Community gains those localities
   - **Result:** Leaders are experts in those localities

3. **City Expertise (75% Rule):**
   - Once a community has covered **75% of a city**, user can claim city expertise
   - **75% Coverage Definition (either/or):**
     - **Option A:** People from 75% of the city regularly commute to the locality for the event
     - **Option B:** Events are hosted in 75% of the localities in the city
   - **Result:** User gains city expertise

4. **State/Regional Expansion:**
   - Continued expansion outside the city:
     - People commute in from outside the city
     - People from neighboring localities to cities/localities where event is hosted
   - **Result:** Community/club gains those places as places of expertise
   - If those places host events, that's also considered expertise gain for the creator

5. **National/Global/Universal Expansion:**
   - Pattern continues:
     - **State:** 75% of state covered (commute or events)
     - **Nation:** 75% of nation covered
     - **Globe:** 75% of globe covered
   - **Universal:** Once 75% of the globe hosts an event or has regularly gone to an event

**Example - Gowanus Coffee Walk:**
1. User creates "Gowanus Coffee Walk" in Gowanus
2. Event grows → People from Park Slope, Red Hook, Carroll Gardens join
3. Those people create events in their localities
4. Community gains: Gowanus, Park Slope, Red Hook, Carroll Gardens
5. Leaders are experts in all those localities
6. Events hosted in 75% of Brooklyn localities → User gains city expertise (Brooklyn)
7. Events expand to Manhattan, Queens → User gains city expertise in those cities
8. 75% of NYC covered → User gains city expertise in NYC
9. Expansion continues to other cities/states → Higher level expertise

**Key Points:**
- Natural expansion through community growth
- 75% threshold for each geographic level
- Two ways to measure coverage: commute patterns OR event hosting
- Leaders gain expertise in all localities where community is active

### **Club Leaders as Experts:**

**Club leaders should be considered experts.**

**Qualification:**
- Leading a successful club/community
- Organizing events that expand geographically
- Building community across localities
- Managing admin team and hierarchy

**Expertise Recognition:**
- Club leaders gain expertise in all localities where club hosts events
- Leadership role itself grants expert status
- Community building expertise recognized

### **Events Page Organization:**

**Clubs and communities should have a uniform tab in the events page.**

**Structure:**
- **Community Tab** - Non-expert events (friends, contacts)
- **Locality Tab** - Events in user's locality
- **City Tab** - Events in user's city
- **State Tab** - Events in user's state
- **Nation Tab** - Events in user's nation
- **Globe Tab** - Global events
- **Universe Tab** - Universal events
- **Clubs/Communities Tab** - All club and community events (uniform tab)

**Clubs/Communities Tab Features:**
- Shows all events from clubs/communities user is part of
- Shows clubs/communities user can join
- Shows club/community events expanding to user's area
- Club/community discovery and joining

### **Club/Community Pages (Special UI/UX):**

**There should be a special page in the UI/UX for club/community pages that shows their expertise coverage by locality.**

**Page Features:**
- **Expertise Coverage Map/Visualization:**
  - Shows all localities where club/community has expertise
  - Visual representation of geographic coverage
  - Color-coded by expertise level (local, city, state, national, global, universal)
  - Shows coverage percentage for each geographic level

- **Coverage Metrics:**
  - Locality coverage (list of all localities)
  - City coverage (75% threshold indicator)
  - State coverage (75% threshold indicator)
  - National coverage (75% threshold indicator)
  - Global coverage (75% threshold indicator)
  - Universal status (if achieved)

- **Expansion Tracking:**
  - Shows how community expanded from original locality
  - Timeline of expansion
  - Events hosted in each locality
  - Commute patterns (people traveling to events)

- **Leader Expertise Display:**
  - Shows expertise levels of club leaders
  - Expertise gained through club expansion
  - Geographic expertise map for each leader

**Example Display:**
```
Greenpoint Coffee Club
├─ Original Locality: Greenpoint ✅
├─ Expanded Localities: Williamsburg, Park Slope, DUMBO ✅
├─ City Coverage: Brooklyn (78% - City Expert Achieved) ✅
├─ City Coverage: Manhattan (45% - In Progress)
├─ State Coverage: NY (12% - In Progress)
└─ Visual Map: [Interactive map showing coverage]
```

### **Club/Community Features:**

**Organizational:**
- Leader designation and permissions
- Admin team management
- Internal hierarchy (roles, permissions)
- Member management

**Event Hosting:**
- Host events in original locality
- Expand events to other localities/cities/states/nations
- Multi-location event coordination
- Event series across geographies

**Community Building:**
- Member engagement
- Community growth tracking
- Cross-locality community building
- Expertise recognition for leaders and active members

### **Requirements for Upgrade:**

**Frequency Hosting:**
- How often an event is hosted (recurring pattern)
- Number of times hosted
- Consistent hosting schedule

**Strong Following:**
- Users actively returning (repeat attendees)
- Users actively going (consistent attendance)
- Event growing by:
  - **Size:** Number of attendees increasing over time
  - **Diversity:** Based on AI agents - diverse user types attending (different personalities, vibes, backgrounds)

**User Interaction:**
- How users interact with the event matters
- Engagement patterns (RSVPs, actual attendance, post-event engagement)
- Community building indicators

**All Factors Play a Part:**
- Number of times hosted
- Number of attendees
- Pattern (recurring schedule)
- User interaction and engagement
- Growth metrics (size + diversity)

**Example:**
- Community event hosted 5 times over 2 months
- Grows from 8 → 12 → 15 → 18 → 22 attendees
- AI detects diverse user types attending (different personality archetypes, vibes)
- Users actively returning (40% repeat attendees)
- High engagement (RSVPs, post-event feedback)
- Host can upgrade to "local event" (becomes local expert event)

---

## 📊 **Implementation Priorities**

### **Phase 1: Core Changes**
1. ✅ Local experts can host events in their locality
2. ✅ Geographic hierarchy enforcement (local → city → state → national)
3. ✅ Local expert qualification system (dynamic thresholds based on locality values)
4. ✅ Event matching signals integration (events hosted, ratings, followers, etc.)

### **Phase 2: Event Discovery & Matching**
1. ✅ Local expert priority in event rankings
2. ✅ Cross-locality event sharing for successful local experts
3. ✅ User preference learning for event recommendations
4. ✅ Events page organization (Community, Locality, City, State, etc.)

### **Phase 3: Community Events & Clubs**
1. ✅ Non-expert event hosting (community events)
2. ✅ Community event upgrade path to local events
3. ✅ Community events can't charge on app
4. ✅ Events can create communities
5. ✅ Communities can become clubs (leaders, admin team, hierarchy)
6. ✅ Club events can expand geographically (locality → city → state → nation → globe → universe)
7. ✅ Expertise gain from event expansion (gain expertise in every place event is hosted)
8. ✅ Club leaders recognized as experts
9. ✅ Clubs/Communities tab in events page

### **Phase 4: Golden Expert AI Influence**
1. ✅ Golden expert behavior weighting (10% higher, proportional)
2. ✅ AI personality locality representation influenced by golden experts
3. ✅ Golden expert lists/reviews weighted more heavily
4. ✅ Neighborhood character shaped by golden experts

---

## 🎯 **Success Metrics**

### **Local Expert Engagement:**
- Number of local experts hosting events
- Average events hosted per local expert
- Cross-locality event attendance (users attending events in neighboring localities)

### **Event Discovery:**
- Users finding events they like (match rate)
- Users exploring new categories/locales
- Community event upgrade rate

### **Geographic Diversity:**
- Events distributed across neighborhoods (not just city centers)
- Small neighborhood events getting traction
- Cross-locality community building

### **AI Personality Accuracy:**
- Locality AI personalities reflecting actual neighborhood character
- Golden expert influence measurable in recommendations
- User satisfaction with locality-based recommendations

---

## 📝 **Implementation Notes**

### **Large City Detection:**
✅ **Resolved:** Based on geographic size, population size, and well-documented neighborhoods backed by geography and population data.

### **Neighborhood Boundaries:**
✅ **Resolved:** 
- Primary source: Google Maps
- Hard borders: Well-defined (e.g., NoHo/SoHo)
- Soft borders: Not well-defined (e.g., Nolita/East Village)
- Soft border spots shared with both localities
- AI tracks user behavior to refine borders over time
- Borders become more defined as users visit spots (one locality visits more = spot becomes more associated with that locality)

### **Event Matching Signals:**
✅ **Resolved:** Not a formal "reputation score" - these are signals for matching users to likeminded people:
- Number of successful events hosted
- Average event ratings
- SPOTS followers
- External social following
- Community recognition
- Peer endorsements

### **Local Expert Thresholds:**
✅ **Resolved:** 
- Dynamic thresholds that ebb and flow
- All data considered, but **what users interact with most** (care about most) in each locality takes precedence
- Thresholds adapt to what the locality actually values
- Example: If Greenpoint users interact heavily with coffee, coffee expertise threshold is lower

### **Cross-Locality Connection:**
✅ **Resolved:**
- NOT just about geographic distance
- Based on how connected places are:
  - How people interact (commute, travel, fun)
  - Transportation methods (car, bus, walking, boat, subway, tram)
  - Shared metropolitan/municipal areas
  - User behavior patterns (where people actually go)
- Example: Birmingham metro area (Birmingham, Hoover, Irondale, etc.) - connected by metro area, not just distance

### **All Questions Resolved:**

✅ **Reputation Calculation:** Based on all factors, with locality-specific weighting, geographic interaction patterns, and community building metrics.

✅ **Community Event Upgrade:** Based on frequency hosting, strong following (active returns, growth in size and diversity), and user interaction patterns.

---

## 🤝 **Business-Expert Matching: Vibe-First, Level-Agnostic**

### **Core Principle:**

**Local experts should NOT be skipped over by business sponsors and companies just because they are local (not city, state, or national).**

**Conversely, companies/sponsors/businesses should NOT skip over experts if they aren't from the exact region - if expertise and vibe match, they should be shared.**

### **Matching Priority (In Order):**

1. **VIBE MATCH (PRIMARY - 50% weight)**
   - Personality compatibility
   - Value alignment
   - Quality focus
   - Community orientation
   - Event style preferences
   - Authenticity vs. commercial focus
   - **This is the MOST important factor**

2. **Expertise Match (30% weight)**
   - Category expertise
   - Quality of contributions
   - Community recognition
   - Event/product/idea fit

3. **Geographic Fit (20% weight)**
   - Location is a factor, NOT a blocker
   - Local experts in locality = boost
   - Remote experts with great vibe/expertise = included
   - Geographic level (local/city/state/national) = preference, not requirement

### **AI System Behavior:**

**The AI system should suggest the best option for:**
- The event
- The product
- The idea
- The community
- **But MAINLY the vibes**

**AI Prompt Priority:**
1. Vibe/personality compatibility (PRIMARY)
2. Expertise quality and fit
3. Geographic location (preference, not requirement)
4. Geographic level (local/city/state/national) - lowest priority

### **Implementation Rules:**

1. **No Level-Based Filtering:**
   - `minExpertLevel` should NOT exclude local experts
   - If `minExpertLevel` is set, it should be a preference boost, not a filter
   - Local experts should always be included in matching pool

2. **Vibe Matching Integration:**
   - Integrate personality/vibe matching into business-expert matching
   - Use existing vibe matching system (70%+ compatibility)
   - Vibe match should override geographic level preferences

3. **Geographic Location as Preference, Not Requirement:**
   - Preferred location = boost to score, not filter
   - Remote experts with great vibe/expertise = included
   - Local experts in locality = boost, but not required

4. **AI Prompt Updates:**
   - Emphasize vibe/personality as PRIMARY factor
   - De-emphasize geographic level (local/city/state/national)
   - Focus on: event fit, product fit, idea fit, community fit, VIBE fit

### **Example Scenarios:**

**Scenario 1: Local Expert with Perfect Vibe**
- Local expert in Greenpoint, coffee expertise
- Business in Greenpoint looking for coffee expert
- Vibe match: 85%
- **Result:** Local expert should be TOP match (vibe + local = perfect)

**Scenario 2: City Expert with Good Vibe vs Local Expert with Great Vibe**
- City expert: Good vibe (70%), coffee expertise, NYC-wide
- Local expert: Great vibe (90%), coffee expertise, Greenpoint only
- Business in Greenpoint
- **Result:** Local expert should rank higher (vibe is primary)

**Scenario 3: Remote Expert with Perfect Vibe**
- Expert in San Francisco, coffee expertise
- Business in NYC looking for coffee expert
- Vibe match: 95% (perfect fit)
- **Result:** Should be included and ranked high (vibe > location)

**Scenario 4: Local Expert Outside Region**
- Local expert in Brooklyn, coffee expertise
- Business in Manhattan looking for coffee expert
- Vibe match: 88%
- **Result:** Should be included (vibe + expertise > exact location)

### **Key Changes Needed:**

1. **Update `BusinessExpertMatchingService`:**
   - Remove level-based filtering (or make it preference-only)
   - Add vibe matching integration
   - Prioritize vibe in scoring algorithm
   - Make location a preference boost, not filter

2. **Update `ExpertSearchService.getTopExperts()`:**
   - Remove `minLevel: ExpertiseLevel.city` requirement
   - Include local experts in results
   - Rank by vibe + expertise, not just level

3. **Update AI Prompts:**
   - Emphasize vibe as PRIMARY factor
   - De-emphasize geographic level
   - Focus on best match for event/product/idea/community/vibe

4. **Update `BusinessExpertPreferences`:**
   - `minExpertLevel` should be preference boost, not filter
   - Add vibe matching preferences
   - Location preferences should be boosts, not filters

---

---

## 🤝 **Business-Expert Matching: Vibe-First, Level-Agnostic**

### **Core Principle:**

**Local experts should NOT be skipped over by business sponsors and companies just because they are local (not city, state, or national).**

**Conversely, companies/sponsors/businesses should NOT skip over experts if they aren't from the exact region - if expertise and vibe match, they should be shared.**

### **Matching Priority (In Order):**

1. **VIBE MATCH (PRIMARY - 50% weight)**
   - Personality compatibility
   - Value alignment
   - Quality focus
   - Community orientation
   - Event style preferences
   - Authenticity vs. commercial focus
   - **This is the MOST important factor**

2. **Expertise Match (30% weight)**
   - Category expertise
   - Quality of contributions
   - Community recognition
   - Event/product/idea fit

3. **Geographic Fit (20% weight)**
   - Location is a factor, NOT a blocker
   - Local experts in locality = boost
   - Remote experts with great vibe/expertise = included
   - Geographic level (local/city/state/national) = preference, not requirement

### **AI System Behavior:**

**The AI system should suggest the best option for:**
- The event
- The product
- The idea
- The community
- **But MAINLY the vibes**

**AI Prompt Priority:**
1. Vibe/personality compatibility (PRIMARY)
2. Expertise quality and fit
3. Geographic location (preference, not requirement)
4. Geographic level (local/city/state/national) - lowest priority

### **Implementation Rules:**

1. **No Level-Based Filtering:**
   - `minExpertLevel` should NOT exclude local experts
   - If `minExpertLevel` is set, it should be a preference boost, not a filter
   - Local experts should always be included in matching pool

2. **Vibe Matching Integration:**
   - Integrate personality/vibe matching into business-expert matching
   - Use existing vibe matching system (70%+ compatibility)
   - Vibe match should override geographic level preferences

3. **Geographic Location as Preference, Not Requirement:**
   - Preferred location = boost to score, not filter
   - Remote experts with great vibe/expertise = included
   - Local experts in locality = boost, but not required

4. **AI Prompt Updates:**
   - Emphasize vibe/personality as PRIMARY factor
   - De-emphasize geographic level (local/city/state/national)
   - Focus on: event fit, product fit, idea fit, community fit, **VIBE fit**

### **Example Scenarios:**

**Scenario 1: Local Expert with Perfect Vibe**
- Local expert in Greenpoint, coffee expertise
- Business in Greenpoint looking for coffee expert
- Vibe match: 85%
- **Result:** Local expert should be TOP match (vibe + local = perfect)

**Scenario 2: City Expert with Good Vibe vs Local Expert with Great Vibe**
- City expert: Good vibe (70%), coffee expertise, NYC-wide
- Local expert: Great vibe (90%), coffee expertise, Greenpoint only
- Business in Greenpoint
- **Result:** Local expert should rank higher (vibe is primary)

**Scenario 3: Remote Expert with Perfect Vibe**
- Expert in San Francisco, coffee expertise
- Business in NYC looking for coffee expert
- Vibe match: 95% (perfect fit)
- **Result:** Should be included and ranked high (vibe > location)

**Scenario 4: Local Expert Outside Region**
- Local expert in Brooklyn, coffee expertise
- Business in Manhattan looking for coffee expert
- Vibe match: 88%
- **Result:** Should be included (vibe + expertise > exact location)

---

**Last Updated:** November 23, 2025  
**Status:** Ready for implementation planning

